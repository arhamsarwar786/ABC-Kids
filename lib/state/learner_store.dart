import 'package:flutter/foundation.dart';

import '../data/models/learner.dart';
import '../data/storage/app_storage.dart';

/// Local learner profiles and the active learner.
class LearnerStore extends ChangeNotifier {
  final AppStorage _storage;
  List<LearnerProfile> _learners = [];
  String? _activeId;
  Future<void> _writes = Future.value();

  LearnerStore(this._storage) {
    _reload();
  }

  void _reload() {
    _learners = _storage.loadLearners();
    // Read-only recovery mode can leave no usable profile: play as a
    // temporary guest that is never written over the stored data.
    if (_learners.isEmpty) _learners = [_storage.newGuest()];
    final index = _storage.loadLearnerIndex();
    _activeId = _learners.any((l) => l.id == index.activeId) ? index.activeId : (_learners.isEmpty ? null : _learners.first.id);
  }

  List<LearnerProfile> get learners => List.unmodifiable(_learners);

  LearnerProfile get active {
    return _learners.firstWhere((l) => l.id == _activeId, orElse: () => _learners.first);
  }

  LearningPreferences get preferences => active.preferences;

  Future<void> _enqueue(Future<void> Function() op) {
    return _writes = _writes.then((_) => op()).catchError((Object e) {
      debugPrint('LearnerStore write failed: $e');
    });
  }

  Future<void> _saveIndex() => _storage.saveLearnerIndex(LearnerIndex(activeId: _activeId, ids: _learners.map((l) => l.id).toList()));

  Future<LearnerProfile> addLearner(String nickname, String avatarId) async {
    final p = LearnerProfile(
      id: _storage.newId('learner'),
      nickname: LearnerProfile.cleanNickname(nickname),
      avatarId: avatarId,
      createdAt: DateTime.now(),
    );
    _learners = [..._learners, p];
    notifyListeners();
    await _enqueue(() async {
      await _storage.saveLearner(p);
      await _saveIndex();
    });
    return p;
  }

  Future<void> switchTo(String id) async {
    if (!_learners.any((l) => l.id == id) || id == _activeId) return;
    _activeId = id;
    notifyListeners();
    await _enqueue(_saveIndex);
  }

  Future<void> updateLearner(LearnerProfile p) async {
    _learners = [for (final l in _learners) l.id == p.id ? p : l];
    notifyListeners();
    await _enqueue(() => _storage.saveLearner(p));
  }

  Future<void> updatePreferences(LearningPreferences Function(LearningPreferences) change) =>
      updateLearner(active.copyWith(preferences: change(active.preferences)));

  /// Deletes one learner's profile and progress. If it was the last learner a
  /// fresh guest is created so the child can still play.
  Future<void> deleteLearner(String id) async {
    await _enqueue(() => _storage.deleteLearner(id));
    _learners = _learners.where((l) => l.id != id).toList();
    if (_learners.isEmpty) {
      final guest = _storage.newGuest();
      _learners = [guest];
      await _enqueue(() => _storage.saveLearner(guest));
    }
    if (!_learners.any((l) => l.id == _activeId)) _activeId = _learners.first.id;
    await _enqueue(_saveIndex);
    notifyListeners();
  }

  Future<void> flush() => _writes;
}
