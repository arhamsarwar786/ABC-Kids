import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/audio/audio_coordinator.dart';
import '../../core/design/components/scaffolds.dart';
import '../../core/services/ads_service.dart';
import '../../data/content/audio_manifest.dart';
import '../../data/content/content_catalog.dart';
import '../../data/content/letter_strokes.dart';
import '../../data/models/content.dart';
import '../../data/storage/app_storage.dart';

/// Honest view of which recordings and content exist and are reviewed.
class ContentStatusScreen extends StatelessWidget {
  const ContentStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioCoordinator>();
    final t = Theme.of(context).textTheme;
    final assets = AudioManifest.all.values;
    int count(AudioKind k, bool Function(AudioAsset) f) => assets.where((a) => a.kind == k && f(a)).length;
    final reviewedPhonemes = count(AudioKind.phoneme, (a) => a.usableForPhonics && audio.assetPlayable(a));
    final letterRec = count(AudioKind.letterName, audio.assetPlayable);
    final numberRec = count(AudioKind.numberName, audio.assetPlayable);
    final storage = context.read<AppStorage>();

    Widget row(String title, String body) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(title: Text(title, style: t.titleMedium), subtitle: Text(body)),
        );

    return ParentScaffold(title: 'Content status', children: [
      row('Letter sound recordings (phonemes)',
          '$reviewedPhonemes of 26 reviewed and bundled. Without them, games that need a heard sound use a visual or picture-based alternative, and lessons ask a grown-up to say the sound.'),
      row('Letter recordings',
          '$letterRec of 26 bundled from the original app. Their spoken content has not been transcribed or reviewed. They are only offered as “letter name” in Explore Letters and never used as sounds.'),
      row('Number recordings', '$numberRec of 11 bundled (0–10) from the original app, not yet reviewed.'),
      row('Word recordings',
          'None bundled. Words use your device’s text-to-speech voice when “Device voice for words” is on (${audio.deviceVoiceUsable ? 'available now' : 'not available now'}).'),
      row('Pictures',
          '${ContentCatalog.words.length} picture words drawn as simple vector illustrations for this version; awaiting design review.'),
      row('Letter shapes for building and tracing',
          '${LetterStrokeLibrary.all.length} letters (${LetterStrokeLibrary.all.keys.join(', ')}). Stroke order has not yet been reviewed by a teacher.'),
      row('Sound policy', 'Each letter teaches one sound first; other sounds (for example the “s” in “is”) are deferred. See Help.'),
      row('Content version', ContentCatalog.version),
      if (storage.readOnly || storage.recoveredKeys.isNotEmpty)
        row(
            'Stored data',
            storage.readOnly
                ? 'Data from a newer version of the app was found. It has been left untouched and changes are not being saved.'
                : '${storage.recoveredKeys.length} damaged record(s) were found and kept as backups on this device.'),
    ]);
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ads = context.watch<AdsService>();
    final t = Theme.of(context).textTheme;
    Widget p(String s) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(s, style: t.bodyLarge));
    return ParentScaffold(title: 'Privacy', children: [
      const SectionTitle('What is stored'),
      p('Learner nicknames, chosen pictures, learning preferences, activity results, stickers and settings are stored only on this device. This app does not upload them, and there are no accounts.'),
      p('The app does not use the microphone, camera, photos, contacts or location.'),
      const SectionTitle('Device voice'),
      p('If “Device voice for words” is on, words and instructions are read by your device’s text-to-speech engine. Depending on your device and its settings, that engine may be provided by another company.'),
      const SectionTitle('Advertising'),
      p('This app includes the Google Mobile Ads software. ${ads.policy.childBanners ? 'A small banner ad, clearly labelled “Advertisement”, appears in its own strip at the bottom of the screen. ' : 'No ads are shown in this version. '}'
          'No full-screen, pop-up or video ads are used. '
          'Ad requests are marked for child-directed treatment and limited to G-rated content. When started, the ads software may collect device information as described in Google’s policies.'),
      p('The grown-up check protects settings from young children. It is not a way of giving parental consent.'),
      const SectionTitle('Deleting data'),
      p('Parent area → Learners lets you reset or delete one learner. Uninstalling the app removes all of its data from this device.'),
    ]);
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget p(String s) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(s, style: t.bodyLarge));
    return ParentScaffold(title: 'Help', children: [
      const SectionTitle('Lessons'),
      p('Each lesson meets one sound: small letter first with the big letter beside it, then pictures that start with the sound, then two or three short games and a sticker. You can leave at any time and continue later from Home.'),
      const SectionTitle('Sound recordings'),
      p('Reviewed recordings of single letter sounds are not included yet. Until they are, lessons ask you to say the sound together with your child, and games use pictures, words and letter shapes instead. The app never plays a letter name and calls it a sound.'),
      const SectionTitle('Progress labels'),
      p('New → Explored (seen or heard) → Practising (tried in a game) → Recognised independently (first-try answers on several days). A single answer never changes a label to recognised, and help or demonstrations never count as independent.'),
      const SectionTitle('Mistakes'),
      p('After a wrong answer the app replays the question, then offers fewer choices, then shows the answer. There are no lives, scores or time limits.'),
      const SectionTitle('Break reminders'),
      p('When enabled, a gentle reminder appears at a natural pause after the chosen number of minutes of active play. Your child can finish or keep going. Time spent paused or in the background is not counted.'),
      const SectionTitle('Pausing'),
      p('If the app goes into the background or the screen locks, the activity pauses and sound stops. Tap “Keep playing” to continue.'),
    ]);
  }
}
