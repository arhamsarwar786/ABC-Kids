# Redesign progress checklist

Resume point for the ABC-Kids redesign. Nothing has been committed or pushed.
Legend: [x] done and verified by automated check · [~] implemented, not verified on
a device · [!] blocked (see RELEASE_BLOCKERS.md)

Last update: 2026-11-02 — `flutter analyze` clean, `flutter test` 271/271 passing.

## Phase 1 – audit, baseline, design system, models
- [x] Read-only audit (GAP_ANALYSIS.md); baseline analyze 28 issues, no tests
- [x] Recording inspection (acoustic only) → recordings remain **unverified**
- [x] Fredoka bundled offline (OFL), generated effect sounds
- [x] Design tokens, components, vector art library; board copied to `references/`
- [x] Data models, versioned content catalogue, audio manifest with honest statuses
- [x] Versioned storage, migration, recovery (review points 1–5) — storage_test.dart

## Phase 2 – m vertical slice
- [x] Activity engine — engine_test.dart
- [x] Audio coordinator (logic) · [~] on-device playback/TTS
- [x] Sound path, Meet the Sound, Listen & Discover, games, completion, sticker — flows_test.dart
- [x] Checkpoint resume / start again, background pause + explicit resume, break reminder
- [!] Reviewed phoneme for m (C1)

## Phase 3 – six games + free play
- [x] Pop (visual mode; phoneme mode ready), Feed the Monster, Safari L1/L2, Parking L1/L2, Build, Magic Trail
- [x] Games catalogue, preparation, demo, completion, replay — games_complete_test.dart
- [~] Drag gestures on device

## Phase 4 – alphabet / numbers / shapes
- [x] Explore letters (abc/ABC, letter-name label), Numbers hub/explorer/count & match, Shapes hub/explorer/match/name

## Phase 5 – parents / progress / migration
- [x] Gate, dashboard, learners (add/switch/edit/reset/delete with named confirmation), preferences, device settings, progress details, content status, privacy, help
- [x] Ads moved behind the parent area; integration kept and documented (MONETIZATION.md)

## Phase 6 – polish / regression / build
- [x] Layout sweep 3 sizes × 2 text scales, tap targets, contrast — layout_test.dart
- [x] Debug arm64 APK built (after disk-space retries)
- [x] Emulator run on Medium_Phone_API_35: s lesson end to end, pause/resume, checkpoint after reinstall, real-touch tracing, parent gate, test banner (BUILD_RUN.md)
- [~] Remaining device checks: drag by hand, other games, TalkBack, tablets, iOS

## Toddler simplification and content review (2026-11-03)
- [x] Pig removed (→ pear); vegetable pizza; blocked-word test over content and all `lib/` strings
- [x] Home: one Play button + big ABC / Sounds / Games / 123 / Shapes tiles
- [x] ABC: all 26 letters with pictures, letter book with ◀ ▶ and swipe
- [x] Games start on tap (no setup screen); unavailable games hidden
- [x] Lessons: 2 games by default, tracing off unless a grown-up enables it; very short instructions
- [x] `flutter test` 283/283, analyze clean

## Next steps when resuming
1. Owner decides on AD_ID removal (P1, confirmed in merged manifest).
2. Continue device checks listed in BUILD_RUN.md.
3. Manually verify audio/TTS, drag, lifecycle, TalkBack; record results in BUILD_RUN.md.
4. Commission and review phoneme/word recordings (C1, C2); review stroke paths (C4).

## All 26 letters (2026-11-03)

- [x] Lesson words and pictures for every letter (61 pictures); x uses end-sound pictures.
- [x] Stroke shapes a–z for Build a Letter and Magic Trail (unverified formation).
- [x] Default sound order covers a–z; stored 7-letter orders are completed on load.
- [x] Parent sync: lesson-shaping preference changes drop the stale checkpoint; Keep going
      re-plans when a saved game can no longer run; one unlock rule for path and letter book.
- [x] No look-alike letter or same-start sound distractors.
- [x] Tests: every letter’s lesson plays through to the sticker (starting, and growing with
      tracing), planning per letter with and without word audio, stroke tracing per letter.
- [ ] Teacher review of a–z stroke formation and of the new words/pictures.

## Premium visual refresh (2026-11-03)

- [x] Fonts: Baloo 2 (headings, buttons), Nunito (body), Fredoka kept for teaching letters.
- [x] Icons: Phosphor (filled) through one `AppIcons` map; Material icons removed from UI.
- [x] `Chunky` surface: gradient face, darker 3D lip that sinks on press, coloured glow.
      Used by primary/secondary/icon buttons, Home tiles, game cards, hub cards, path nodes.
- [x] Letter/picture tiles: gradient fill + lip + glow; instruction banner as a white card;
      floating tab bar; soft lilac-to-cream background.
- [x] Retook all store screenshots in the final design.

## Professional UX pass (2026-11-03)

- [x] Illustrated scenes (`SceneBackground`: meadow, sky, ocean, night, town, sunset) behind
      every child screen; each game has its own scene.
- [x] Motion: staggered entrances, gentle bob for characters, pulse on the next sound, confetti
      on correct answers and rewards, sunburst behind stickers. All finite and off with
      Reduce motion; entrances keep their screen-reader labels while fading in.
- [x] New Home: greeting with avatar and sticker count, “next adventure” hero card (letter,
      lesson n of 26, progress bar, Play / Keep going), explore tiles with sub-labels.
- [x] Star-track round progress; reward pill; tagged game cards; tilted sticker book.
- [x] Re-took store screenshots with this design (`docs/store/phone_01–08.png`).
