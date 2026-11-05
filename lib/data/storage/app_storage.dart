import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/device_settings.dart';
import '../models/learner.dart';
import '../models/learner_progress.dart';

/// Versioned local storage on top of SharedPreferences.
///
/// * Legacy keys from the original app are read for migration and never
///   deleted or rewritten.
/// * Each learner's progress is one key, so writes are all-or-nothing per
///   learner, and learners are isolated from each other.
/// * Every read is type-checked. Malformed data is copied to an
///   `abc.recovered.*` key, and that copy must be durably written before the
///   original key may be overwritten.
/// * If the stored schema is newer than this app understands, storage is
///   read-only for the whole session: nothing on disk is changed.
class AppStorage {
  static const int schemaVersion = 1;

  // Legacy keys (original app). Read-only from here on.
  static const String legacyMuteKey = 'mute_sound';
  static const String legacyOnboardingKey = 'onboarding_seen';
  static const String legacyPlaybackSpeedKey = 'playback_speed';
  static const String legacyStarCountKey = 'star_count';

  static const String schemaKey = 'abc.schema';
  static const String deviceKey = 'abc.device';
  static const String learnersKey = 'abc.learners';
  static const String legacyStarsMigratedKey = 'abc.legacyStarsMigratedTo';
  static const String recoveredPrefix = 'abc.recovered.';
  static String learnerKey(String id) => 'abc.learner.$id';
  static String progressKey(String id) => 'abc.progress.$id';

  final SharedPreferences prefs;
  final List<String> recoveryLog = [];
  final Random _random;
  final DateTime Function() _now;

  /// True when stored data comes from a newer schema; all writes are skipped.
  bool _readOnly = false;
  bool get readOnly => _readOnly;

  /// Backups in flight, per original key.
  final Map<String, Future<bool>> _pendingBackups = {};

  /// Keys whose backup could not be written: they are never overwritten.
  final Set<String> _unsafeToOverwrite = {};

  /// Keys already backed up this session (avoids duplicate copies).
  final Set<String> _backedUp = {};
  int _backupSeq = 0;

  AppStorage._(this.prefs, this._random, this._now);

  static Future<AppStorage> open(SharedPreferences prefs, {Random? random, DateTime Function()? now}) async {
    final s = AppStorage._(prefs, random ?? Random(), now ?? DateTime.now);
    await s._migrate();
    return s;
  }

  int get storedSchema => _getInt(schemaKey) ?? 0;

  // ------------------------------------------------------- typed raw reads

  Object? _raw(String key) {
    try {
      return prefs.get(key);
    } catch (_) {
      return null;
    }
  }

  String? _getString(String key) {
    final v = _raw(key);
    return v is String ? v : null;
  }

  int? _getInt(String key) {
    final v = _raw(key);
    return v is int ? v : null;
  }

  bool? _getBool(String key) {
    final v = _raw(key);
    return v is bool ? v : null;
  }

  // ---------------------------------------------------------------- helpers

  String newId(String prefix) {
    final r = _random.nextInt(1 << 32).toRadixString(36);
    return '$prefix-${_now().microsecondsSinceEpoch.toRadixString(36)}-$r';
  }

  /// Reads a JSON object. Wrong-typed or malformed values are backed up and
  /// reported as null.
  Map<String, dynamic>? _readJson(String key) {
    final value = _raw(key);
    if (value == null) return null;
    if (value is! String) {
      _preserve(key, jsonEncode(value is Set ? value.toList() : value), 'stored as ${value.runtimeType}');
      return null;
    }
    try {
      final v = jsonDecode(value);
      if (v is Map<String, dynamic>) return v;
      throw const FormatException('not a JSON object');
    } catch (e) {
      _preserve(key, value, 'malformed: $e');
      return null;
    }
  }

  /// Copies [raw] to a recovery key. The write is tracked so that the original
  /// key is not overwritten until the copy is durable.
  void _preserve(String key, String raw, String why) {
    if (!_backedUp.add(key)) return;
    if (_readOnly) {
      recoveryLog.add('$key is malformed ($why); left untouched (read-only mode).');
      return;
    }
    final backupKey = '$recoveredPrefix$key.${_now().millisecondsSinceEpoch}.${_backupSeq++}';
    final future = prefs.setString(backupKey, raw).then((ok) {
      if (!ok) _unsafeToOverwrite.add(key);
      return ok;
    }, onError: (Object e) {
      _unsafeToOverwrite.add(key);
      return false;
    });
    _pendingBackups[key] = future;
    recoveryLog.add('$key → $backupKey ($why)');
    debugPrint('AppStorage: preserving $key as $backupKey ($why)');
  }

  /// Waits for all backups to finish. Returns false if any failed.
  Future<bool> flushBackups() async {
    final results = await Future.wait(_pendingBackups.values);
    return results.every((ok) => ok);
  }

  Future<void> _writeJson(String key, Map<String, dynamic> value) async {
    if (_readOnly) {
      recoveryLog.add('Skipped write to $key (read-only mode).');
      return;
    }
    final backup = _pendingBackups[key];
    if (backup != null && !await backup) {
      throw StateError('Backup of malformed $key failed; refusing to overwrite it.');
    }
    if (_unsafeToOverwrite.contains(key)) {
      throw StateError('Backup of malformed $key failed; refusing to overwrite it.');
    }
    final ok = await prefs.setString(key, jsonEncode(value));
    if (!ok) throw StateError('Could not write $key');
  }

  Future<void> _remove(String key) async {
    if (_readOnly) return;
    await prefs.remove(key);
  }

  // -------------------------------------------------------------- migration

  Future<void> _migrate() async {
    final from = storedSchema;
    if (from > schemaVersion) {
      _readOnly = true;
      recoveryLog.add('Stored schema $from is newer than $schemaVersion; storage is read-only for this session.');
      return;
    }
    if (from < 1 && _readJson(deviceKey) == null && !_unsafeToOverwrite.contains(deviceKey)) {
      await flushBackups();
      if (!_unsafeToOverwrite.contains(deviceKey)) {
        await saveDeviceSettings(DeviceSettings(
          musicMuted: _getBool(legacyMuteKey) ?? false,
          firstRunComplete: _getBool(legacyOnboardingKey) ?? false,
        ));
      }
    }
    // Always ensure there is at least one valid learner (idempotent).
    var learners = loadLearners();
    if (learners.isEmpty) {
      final guest = newGuest();
      await flushBackups();
      await saveLearner(guest);
      await saveLearnerIndex(LearnerIndex(activeId: guest.id, ids: [guest.id]));
      learners = [guest];
    }
    final index = loadLearnerIndex();
    await _migrateLegacyStars(index.activeId ?? learners.first.id);
    if (from < schemaVersion) await prefs.setInt(schemaKey, schemaVersion);
  }

  LearnerProfile newGuest() => LearnerProfile(
        id: newId('learner'),
        nickname: 'Explorer',
        avatarId: Avatar.all.first.id,
        createdAt: _now(),
        isGuest: true,
      );

  /// Legacy stars (earned in the original app) are kept as a full count on
  /// the first learner and shown on the stickers page. Assigning (not adding)
  /// the count makes this idempotent; `star_count` itself is never changed.
  Future<void> _migrateLegacyStars(String learnerId) async {
    if (_getString(legacyStarsMigratedKey) != null) return;
    final stars = _getInt(legacyStarCountKey) ?? 0;
    if (stars > 0) {
      final data = loadProgress(learnerId);
      data.legacyStars = stars;
      await flushBackups();
      await saveProgress(data);
    }
    await prefs.setString(legacyStarsMigratedKey, learnerId);
  }

  // --------------------------------------------------------------- device

  DeviceSettings loadDeviceSettings() {
    final j = _readJson(deviceKey);
    return j == null ? const DeviceSettings() : DeviceSettings.fromJson(j);
  }

  Future<void> saveDeviceSettings(DeviceSettings s) => _writeJson(deviceKey, s.toJson());

  // -------------------------------------------------------------- learners

  /// Index of learners whose profiles actually parse. Falls back to scanning
  /// stored profiles when the index is missing or broken.
  LearnerIndex loadLearnerIndex() {
    final j = _readJson(learnersKey);
    if (j != null) {
      final rawIds = j['ids'];
      final ids = rawIds is List ? rawIds.whereType<String>().toList() : <String>[];
      if (rawIds is! List) _preserve(learnersKey, jsonEncode(j), 'ids is not a list');
      final valid = ids.where((id) => loadLearner(id) != null).toList();
      if (valid.isNotEmpty) {
        final active = j['activeId'];
        return LearnerIndex(activeId: valid.contains(active) ? active as String : valid.first, ids: valid);
      }
    }
    final rebuilt = prefs
        .getKeys()
        .where((k) => k.startsWith('abc.learner.'))
        .map((k) => k.substring('abc.learner.'.length))
        .where((id) => loadLearner(id) != null)
        .toList()
      ..sort();
    return LearnerIndex(activeId: rebuilt.isEmpty ? null : rebuilt.first, ids: rebuilt);
  }

  Future<void> saveLearnerIndex(LearnerIndex index) =>
      _writeJson(learnersKey, {'activeId': index.activeId, 'ids': index.ids});

  /// Returns the profile, or null (with the raw record preserved) if invalid.
  LearnerProfile? loadLearner(String id) {
    final key = learnerKey(id);
    final j = _readJson(key);
    if (j == null) return null;
    LearnerProfile? p;
    try {
      p = LearnerProfile.tryFromJson(j);
    } catch (_) {
      p = null;
    }
    if (p == null || p.id != id) {
      _preserve(key, jsonEncode(j), 'invalid profile');
      return null;
    }
    return p;
  }

  List<LearnerProfile> loadLearners() => [
        for (final id in loadLearnerIndex().ids) ?loadLearner(id),
      ];

  Future<void> saveLearner(LearnerProfile p) => _writeJson(learnerKey(p.id), p.toJson());

  /// Removes exactly this learner's profile and progress. Other learners and
  /// device settings are untouched.
  Future<void> deleteLearner(String id) async {
    final index = loadLearnerIndex();
    final ids = index.ids.where((x) => x != id).toList();
    await saveLearnerIndex(LearnerIndex(
      activeId: index.activeId == id ? (ids.isEmpty ? null : ids.first) : index.activeId,
      ids: ids,
    ));
    await _remove(progressKey(id));
    await _remove(learnerKey(id));
  }

  // -------------------------------------------------------------- progress

  LearnerProgressData loadProgress(String learnerId) {
    final key = progressKey(learnerId);
    final j = _readJson(key);
    if (j == null) return LearnerProgressData(learnerId: learnerId);
    var dropped = 0;
    try {
      final data = LearnerProgressData.fromJson(learnerId, j, droppedEntries: (n) => dropped = n);
      if (dropped > 0) _preserve(key, jsonEncode(j), '$dropped invalid entries skipped');
      return data;
    } catch (e) {
      _preserve(key, jsonEncode(j), 'unreadable progress: $e');
      return LearnerProgressData(learnerId: learnerId);
    }
  }

  /// Skips the write if the learner no longer exists, so a late write can
  /// never resurrect a deleted learner's data.
  Future<void> saveProgress(LearnerProgressData data) async {
    if (!prefs.containsKey(learnerKey(data.learnerId))) return;
    await _writeJson(progressKey(data.learnerId), data.toJson());
  }

  /// Keys that hold preserved copies of malformed data.
  List<String> get recoveredKeys => prefs.getKeys().where((k) => k.startsWith(recoveredPrefix)).toList()..sort();
}

class LearnerIndex {
  final String? activeId;
  final List<String> ids;
  const LearnerIndex({required this.activeId, required this.ids});
}
