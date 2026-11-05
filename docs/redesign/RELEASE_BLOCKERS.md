# Release blockers and known gaps

Nothing in this repository has been verified as store-ready or policy-compliant.
Items below must be resolved (or explicitly accepted by the product owner)
before any release.

## Content (phonics)

| # | Blocker | Current behaviour | To resolve |
|---|---------|-------------------|------------|
| C1 | **No phoneme recordings.** `assets/audio/abc_letter_sound/*.mp3` were inspected only acoustically (duration and zero-crossing pattern suggest letter names, e.g. `s` = vowel then hiss). Nobody has listened to or transcribed them. They stay `unverified` and are never used as sounds. | Lessons show a grown-up prompt (“say the sound /m/ together”). Pop the Sound runs as visual **Pop the Letter**. Feed the Monster and Safari level 2 show the letter visually and use word audio. | Record isolated phonemes (s a t p i n m first), have a qualified person review them, add files to `assets/audio/phonemes/`, list the letters in `AudioManifest.reviewedPhonemes`. |
| C2 | **No word recordings.** | Whole words use the device text-to-speech voice when the parent setting is on (default on). Word games are unavailable if no voice exists. | Record and review word audio, register `audioId` on each `WordExample`. |
| C3 | Letter and number recordings from the original app are **unverified** (content, accent, licence). | Offered only as “Hear the letter name” in Explore Letters and number audio in the Numbers explorer. | Listen, transcribe, confirm licence and accent; then mark reviewed. |
| C4 | Stroke paths and stroke order (`lib/data/content/letter_strokes.dart`) for s a t p i n m are **not teacher-reviewed**. | Used by Build a Letter and Magic Trail. | Review against the chosen handwriting scheme. |
| C5 | Picture illustrations are project-drawn vector art awaiting design review. | Shown everywhere pictures appear. | Design review or replace with commissioned illustrations. |
| C6 | Background music licence is not documented in the repo. | Plays at low volume when not muted. | Confirm licence or replace. |

## Commercial / policy (see MONETIZATION.md)

| # | Blocker | Notes |
|---|---------|-------|
| P1 | **Addressed in 1.1.0:** `AndroidManifest.xml` removes `AD_ID`, `ACCESS_ADSERVICES_AD_ID`, `ACCESS_ADSERVICES_ATTRIBUTION` and `ACCESS_ADSERVICES_TOPICS` with `tools:node="remove"` (checked in the merged profile manifest). Original issue: `play-services-ads-identifier` (pulled in by `google_mobile_ads` → `play-services-ads:25.4.0`) merges `com.google.android.gms.permission.AD_ID` and `android.permission.ACCESS_ADSERVICES_AD_ID`. Google Play: apps solely targeting children “should not request AD_ID permission when targeting Android API 33 or higher”. | **Confirmed** in this build’s merged debug manifest, together with `ACCESS_ADSERVICES_TOPICS` and `ACCESS_ADSERVICES_ATTRIBUTION`. Decision needed: remove with `tools:node="remove"` or change target audience. |
| P2 | Families self-certification of `google_mobile_ads 9.1.0` / `play-services-ads 25.4.0` not verified. | Required for ads shown to children or users of unknown age. |
| P3 | Apple Kids Category: third-party advertising should not be included except limited contextual cases with human-reviewed creatives, and device information should not be sent to third parties even in adult sections without parental consent. The parent-area banner may conflict. | Decide whether to ship ads on iOS at all. A parental gate is not consent. |
| P4 | Privacy policy, Data safety form and App Privacy labels must be written to match the code. | In-app Privacy page describes current behaviour; it is not a legal policy. |

## Build and verification

| # | Blocker | Notes |
|---|---------|-------|
| B1 | Build machine disk is nearly full (≈1.7 GB free). Debug arm64 APK built after retries; a release build may fail for space. | See BUILD_RUN.md. |
| B2 | Partial device verification only (one emulator, Android 15). Audio not heard by a person; drag by hand, TalkBack/VoiceOver, tablets, real hardware not checked. | Emulator results in BUILD_RUN.md. |
| B3 | iOS build not attempted. Release signing requires `android/key.properties` and the upload keystore (both absent on this machine; not created). | Needed to build the release `.aab`. |
