# Architecture

Flutter + Provider (ChangeNotifier) as before; feature folders under `lib/features`.

```
lib/
  main.dart              bootstrap: storage → stores → asset manifest → audio → providers
  app/                   MaterialApp, theme (Fredoka bundled), text scaling, reduced motion
  core/
    audio/               AudioCoordinator (single owner of audio) + AudioDriver (platform / fake)
    design/              tokens, components (scaffolds, buttons, tiles, feedback, settings), art (vector painters)
    services/            AdsService (lazy, placement policy)
  data/
    models/              LearnerProfile, LearningPreferences, DeviceSettings, LetterContent, WordExample,
                         AudioAsset, ActivityDefinition, LessonPlan/Step, ActivityAttempt, SkillProgress,
                         StickerAward, SessionCheckpoint, LearnerProgressData
    content/             ContentCatalog (versioned), AudioManifest, LetterStrokeLibrary, StickerCatalog
    storage/             AppStorage (versioned SharedPreferences, migration, recovery)
  domain/                ContentAvailability, LessonPlanner, ActiveTimeTracker
  engine/                ActivityEngine state machine + Scheduler
  state/                 SettingsStore, LearnerStore, ProgressStore
  features/              welcome, shell, home, sound_path, alphabet, lesson, games, stickers,
                         numbers, shapes, parent, shared
```

## Activity engine (`lib/engine/activity_engine.dart`)

States: `preparing → demonstrating → prompting → awaitingInput → evaluating →
feedback → nextRound → … → completed`, plus `paused`, `error`, `exited`.

- Input only in `awaitingInput`; answering moves to `evaluating` first (double-tap lock).
- Wrong answer 1: replay prompt. Wrong 2: one fewer choice (or highlight when only two remain), hint recorded. Wrong 3: demonstration; outcome `demonstrated` (never independent).
- No lives, scores or failure state.
- All delays are cancellable `Scheduler` tasks; `pause`/`exit` cancel them and bump a generation counter so late async prompt results are ignored.
- `resume()` is explicit and replays the current prompt, keeping retry/hint state.
- Prompt returning false (essential audio unavailable) → `error` with retry, or the screen offers another activity. Never silent success.
- `atBoundary` is called between rounds; the break reminder can finish early there.

`GameState` (`features/games/game_framework.dart`) wires engine → evidence
recording, effects, lifecycle (background ⇒ pause + stop narration + pause
active time), reminder, error UI, back/pause, music suspension.

## Evidence and labels

Each round writes an `ActivityAttempt` (learner, activity, game, content version,
domain, target, outcome, hints, retries, demonstration, lesson vs free play,
timestamp). Domains are separate: exposure, soundLetter, letterName,
beginningSound, wordPicture, visualMatching, caseMatching, construction,
tracing, number, shapeMatching, shapeNaming. Only soundLetter and
beginningSound count as phonics.

`ProgressCriteria` (defaults, in `data/models/progress.dart`):
- **Explored**: exposure only.
- **Practising**: any practice attempt.
- **Recognised independently**: ≥4 first-try correct, on ≥2 distinct days,
  last 5 tries ≥80% first-try. Assisted and demonstrated answers never count.
  A single answer can never meet this. The word “mastery” is not used.

## Lesson planning (`domain/lesson_planner.dart`)

intro → picture discovery → 2 (starting) or 3 (growing) games → optional Magic
Trail → completion. Always includes one phonics-evidence game when available
(least recently played), then scores the rest by evidence, variety and
availability. Distractors come only from introduced sounds; visual games may use
any letters. Availability (`domain/availability.dart`) checks the real bundle:
Pop needs reviewed phonemes for phoneme mode (else visual mode); Feed/Safari
need word audio; Build/Trail need stroke data.

## Audio (`core/audio/audio_coordinator.dart`)

One narration at a time (clip or device voice); a new request stops the old
one, identical requests within 300 ms are ignored, nothing is queued. Music
ducks to 25% under narration, pauses while suspended (ads, paused activity) or
in background. Backgrounding stops narration and emits `AppPresence.background`.
Only bundled assets whose kind matches are played; phonemes only when reviewed.
Device TTS is only used for whole words/instructions, never single letters.
Limits: OS audio-focus loss and output-route changes (e.g. headphones unplugged)
are not handled separately beyond app lifecycle events.

## Storage (`data/storage/app_storage.dart`)

Schema `abc.schema = 1`. Keys: `abc.device` (device settings), `abc.learners`
(index), `abc.learner.<id>`, `abc.progress.<id>` (attempts ≤400, skills,
stickers, completed lessons, recent games, checkpoint, legacy stars).

- Legacy keys `mute_sound`, `onboarding_seen`, `playback_speed`, `star_count`
  are read once and never modified. Stars → `legacyStars` (full count) on the
  first learner, guarded by `abc.legacyStarsMigratedTo`.
- Newer stored schema ⇒ read-only session (no writes at all).
- Every read is type-checked; malformed values are copied to
  `abc.recovered.<key>.<ts>.<n>`, and the original key is not overwritten until
  that backup write succeeds.
- Per-learner progress is one key (atomic per learner); late writes for a
  deleted learner are dropped; invalid checkpoints are cleared without touching
  progress.

## Ads

See MONETIZATION.md. SDK starts lazily from the parent dashboard only.
