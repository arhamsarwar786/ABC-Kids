# Build, run and test

## Prerequisites (as found on this machine)

- Flutter 3.38.6 stable (Dart 3.10); `pubspec.yaml` requires Dart `^3.10.0`.
- Android SDK 36, Java 17 (Android Studio JBR), AGP 8.11.1, Kotlin 2.2.20, minSdk 24.
- AVD available: `Medium_Phone_API_35` (android-35 arm64 image).
- Xcode 26.2, iOS deployment target 13.0, CocoaPods.
- Release signing needs `android/key.properties` (gitignored; not present).
- `.vscode/settings.json` points at another developer’s Windows SDK path (unchanged).

## Commands

```bash
flutter pub get
flutter analyze
flutter test                     # all suites
flutter run                      # device / emulator
flutter build apk --debug        # test APK → build/app/outputs/flutter-apk/app-debug.apk
flutter emulators --launch Medium_Phone_API_35
```

## Test suites

| File | Covers |
|---|---|
| `test/storage_test.dart` | migration from original prefs, legacy stars (full count), idempotent reopen, future-schema read-only, wrong types, malformed JSON backup, failed-backup blocks overwrite, all-malformed profiles → guest, learner isolation, delete without resurrection, sticker idempotency, checkpoint validity and round-trip |
| `test/engine_test.dart` | state transitions, double-tap lock, retry → hint → demonstration, assisted vs independent, pause/resume, exit cancels timers, audio failure → error/retry, skip demo, early finish at boundary, task rounds |
| `test/domain_test.dart` | content honesty (no reviewed phonemes, letter recordings unverified), availability, planner (structure, readiness, tracing, distractors, no word audio, variety, next sound), progress labels, tracing tracker, parent gate questions, active-time reminder |
| `test/flows_test.dart` | m lesson end to end (no phoneme played, grown-up prompt, checkpoints, game, sticker, evidence domain), resume from Home, background pause requiring explicit resume, demonstration after three mistakes, exit without results |
| `test/games_complete_test.dart` | every game type/level reaches completion and records its own domain; Build a Letter tap placement incl. rejected placement |
| `test/layout_test.dart` | 22 screens + 11 game configurations at 320×568, 390×844, 1024×1366 × text scale 1.0 / 2.0 with no overflow/exception; 56 px child tap targets; Android tap-target and text-contrast guidelines on Home |

## Results in this session (2026-11-02)

- `flutter analyze`: **No issues found** (baseline before work: 28 issues).
- `flutter test`: **271 tests passed**, 0 failed.
- `flutter build apk --debug`: failed twice with `No space left on device` (≈171 MB, then ≈2.7 GB free). Later succeeded as `flutter build apk --debug --target-platform android-arm64` → `build/app/outputs/flutter-apk/app-debug.apk` (94 MB).

## Emulator run (2026-11-02, Medium_Phone_API_35, Android 15 / API 35 arm64, 1080×2400, cold boot)

Checked on the emulator, with screenshots and logcat as evidence:
- First launch → Welcome → Play → Home with guest “Explorer”; tabs Home / Games / My Stickers.
- Full guided lesson for **s**: Meet the Sound (no “Hear the sound”, grown-up prompt shown), Listen & Discover, Sound Safari (words), Feed the Monster, Magic Trail, You did it! with a new sticker, Next sound: a.
- Device TTS: Google TTS loaded its en-GB voice; utterance for “sun” started and completed (logcat). The audio itself was **not heard** by a person.
- Wrong answer → gentle feedback; correct → “Lovely!”.
- Home key during a game → on return shows **Paused** and waits for “Keep playing”; round progress kept.
- Checkpoint survived app reinstall and process restart (“Sound s · step 5 of 6”, Resume / Start again).
- Magic Trail traced with real touch events (`input motionevent`) along the s path → completed.
- Flutter semantics labels exposed to Android accessibility (read via `uiautomator`); TalkBack itself not tested.
- Parent gate (written multiplication, four answers) → dashboard with correct evidence; ads SDK started at that point and a Google **Test Ad** banner showed in the parent area only.
- Merged debug manifest contains `com.google.android.gms.permission.AD_ID`, `ACCESS_ADSERVICES_AD_ID`, `ACCESS_ADSERVICES_TOPICS`, `ACCESS_ADSERVICES_ATTRIBUTION` (see RELEASE_BLOCKERS P1).

Fixed after the emulator run: tracing/build letters too small and blob-like (now fitted to the area); upper/lower case sizes on Meet the Sound; replay button no longer disappears during feedback; eye contrast on letter faces; sticker slot alignment.

Not verified: drag gestures by hand, Pop/Parking/Build/Count/Shapes on device, music ducking by ear, audio-focus interruptions, iOS, release build, TalkBack/VoiceOver, tablets.

## Physical device attempt (2026-11-02, Redmi 13C 23106RN0DA, Android 15, USB)

- The phone already has the Play Store release (1.0.1, versionCode 10). Debug/profile builds now use
  `applicationIdSuffix ".dev"` and the label “ABC Kids (dev)” so they install **next to** it without
  touching its data. Release id, label and signing are unchanged.
- Ad IDs: test units are now used in debug **and profile** builds (`!kReleaseMode`); production
  units only in release builds.
- Install **failed**: `INSTALL_FAILED_INSUFFICIENT_STORAGE` — phone has ≈0.5 GB free of 106 GB.
  Built and ready: `build/app/outputs/flutter-apk/app-profile.apk` (37.6 MB, AOT, arm64).
  Install with `adb install build/app/outputs/flutter-apk/app-profile.apk` after freeing ~1–2 GB.
