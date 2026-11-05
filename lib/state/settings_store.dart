import 'package:flutter/foundation.dart';

import '../data/models/device_settings.dart';
import '../data/storage/app_storage.dart';

class SettingsStore extends ChangeNotifier {
  final AppStorage _storage;
  DeviceSettings _settings;
  Future<void> _writes = Future.value();

  SettingsStore(this._storage) : _settings = _storage.loadDeviceSettings();

  DeviceSettings get settings => _settings;

  Future<void> update(DeviceSettings Function(DeviceSettings) change) {
    _settings = change(_settings);
    notifyListeners();
    final snapshot = _settings;
    return _writes = _writes.then((_) => _storage.saveDeviceSettings(snapshot)).catchError((Object e) {
      debugPrint('SettingsStore write failed: $e');
    });
  }
}
