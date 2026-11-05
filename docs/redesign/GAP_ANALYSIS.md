# Requirements gap analysis

Status: ✅ implemented and covered by automated tests · 🟡 implemented, not
verified on a device or partially met · ⛔ blocked (RELEASE_BLOCKERS.md).

## Original app (audit summary)

Splash → 3-page onboarding → Home (ABC / Numbers cards, star/ads button,
settings) → letter/number grid → detail with letter-name audio and speed slider.
No tests. Defects found: background music resumed on Detail after ads; session
interstitial counter never reset; mute ignored effects; double-tap pushed two
routes; invisible onboarding icons; unused widgets and dependencies; runtime
font download; ads shown throughout child play.

## Requirements

| Area | Requirement | Status |
|---|---|---|
| Design | Ivory/purple/navy/pastels, rounded type (Fredoka bundled), soft cards, calm vector art, lavender round controls, purple CTAs | 🟡 matches written direction and board; no designer review |
| Design | Phones/tablets/text scaling, 20–24 px gutters, 56 px targets, semantics, reduced motion | ✅ layout sweep, tap-target and contrast guidelines; 🟡 screen-reader pass not done |
| Components | Child/parent scaffolds, back/home/audio/pause, buttons, progress, letter/picture tiles, path nodes, instruction/feedback/sticker/settings/error | ✅ |
| Navigation | Home / Games / My Stickers tabs hidden in activities; Welcome → Play → Home; guest learner; optional parent setup | ✅ |
| Navigation | Continue learning with Resume / Start again | ✅ flow test |
| Lessons | Configurable sequence s a t p i n (+ m); sound path new/explored/practising; Explore Letters | ✅ |
| Lessons | Meet the Sound lowercase-first with uppercase, reviewed phoneme, picture | 🟡 implemented; ⛔ no reviewed phonemes → grown-up prompt |
| Lessons | Picture discovery 2–3 words with replay | ✅ (device voice; ⛔ no recordings) |
| Lessons | 2–3 games chosen by introduced sounds, readiness, evidence, assets, variety; completion + sticker; next / finish | ✅ |
| Games | Six games across letters, prep/demo/activity/completion/replay, practice vs guided evidence | ✅ completion tests; Pop phoneme mode ⛔ until recordings |
| Games | Tap and drag (Feed, Parking, Build); Build forgiving snap, no overlap, auto finish | ✅ tap tested; 🟡 drag not exercised on device |
| Games | Magic Trail explicit strokes, start dot, tolerance, cancel/restart, demo, skip, no percentages, optional | ✅ logic tests; ⛔ stroke review |
| Engine | Full state set, locks, cancellation, replay, pause/resume, safe exit, escalation, assistance recorded | ✅ |
| Engine | Configurable reminder at boundary, no hard limit; background pauses input/narration/time; explicit resume | ✅ |
| Engine | Checkpoints restore; invalid recover without losing progress | ✅ |
| Numbers | 1–10 explorer with audio, count-and-match with 2–3 choices, hub/replay/home | ✅ (number audio unverified) |
| Shapes | Explorer, identical matching with independent colours, named selection, separate domains | ✅ |
| Data | Listed models, stable ids, content version, sound policy, distinct audio kinds, availability | ✅ |
| Data | Per-attempt record fields, separated evidence domains, documented label criteria, no mastery | ✅ |
| Data | Idempotent per-learner stickers, empty state, no streaks | ✅ |
| Storage | Keep legacy prefs, migrate stars, versioned schema, recovery retaining originals, isolation | ✅ incl. review points 1–5 |
| Parents | Gate (not hold), dashboard, learners add/switch/delete (nickname + avatar) | ✅ |
| Parents | Preferences that change behaviour; real accent options only; separate volumes; music mute; narration preview; normal-speed phonics; accessibility; progress details; privacy/help | ✅ 🟡 preview needs device |
| Parents | Fresh gate + learner-named confirmation listing removed data; others preserved | ✅ storage tests |
| Audio | Central coordinator, no overlap/backlog, ducking, exit cancel, lifecycle, failure UI | ✅ logic; 🟡 hardware; output-route handling not implemented |
| Audio | Honest asset status, no letter names as phonics, no TTS phonemes | ✅ tests |
| Commercial | No ads/analytics/links in child play; ads kept and documented; parent-only access | ✅ code; ⛔ AD_ID / Families SDK / Apple Kids decisions |
| Delivery | Docs, checklist, flow map, architecture, assets, blockers, build | ✅ |
| Delivery | analyze/test, APK, emulator | ✅ analyze/test; ⛔ APK and emulator (disk full) |
