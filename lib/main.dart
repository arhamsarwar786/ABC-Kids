import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/audio/audio_coordinator.dart';
import 'core/audio/audio_driver.dart';
import 'core/services/ads_service.dart';
import 'data/storage/app_storage.dart';
import 'domain/active_time.dart';
import 'state/learner_store.dart';
import 'state/progress_store.dart';
import 'state/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const _Bootstrap());
}

/// Loads local data (with migration and recovery) before showing the app.
/// Everything is offline: no account, network or microphone is needed.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late Future<_Services> _services = _load();

  Future<_Services> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = await AppStorage.open(prefs);
    final settings = SettingsStore(storage);
    final learners = LearnerStore(storage);
    final progress = ProgressStore(storage, learners);
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final audio = AudioCoordinator(PlatformAudioDriver(), settings, bundledAssets: manifest.listAssets().toSet());
    unawaited(audio.init());
    return _Services(storage, settings, learners, progress, audio, AdsService(policy: AdPlacementPolicy.forPlatform(), audio: audio));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Services>(
      future: _services,
      builder: (context, snap) {
        if (snap.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Something went wrong while opening the app.', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: () => setState(() => _services = _load()), child: const Text('Try again')),
                  ]),
                ),
              ),
            ),
          );
        }
        final s = snap.data;
        if (s == null) {
          return const ColoredBox(color: Color(0xFFFAFAF7), child: Center(child: CircularProgressIndicator()));
        }
        return MultiProvider(
          providers: [
            Provider.value(value: s.storage),
            ChangeNotifierProvider.value(value: s.settings),
            ChangeNotifierProvider.value(value: s.learners),
            ChangeNotifierProvider.value(value: s.progress),
            ChangeNotifierProvider.value(value: s.audio),
            ChangeNotifierProvider.value(value: s.ads),
            ChangeNotifierProvider(create: (_) => ActiveTimeTracker()),
          ],
          child: const AbcKidsApp(),
        );
      },
    );
  }
}

class _Services {
  final AppStorage storage;
  final SettingsStore settings;
  final LearnerStore learners;
  final ProgressStore progress;
  final AudioCoordinator audio;
  final AdsService ads;
  _Services(this.storage, this.settings, this.learners, this.progress, this.audio, this.ads);
}
