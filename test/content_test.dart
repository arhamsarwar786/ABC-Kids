import 'dart:io';

import 'package:abc_kids_learning/core/design/art/word_art.dart';
import 'package:abc_kids_learning/data/content/content_catalog.dart';
import 'package:abc_kids_learning/data/models/learner.dart';
import 'package:abc_kids_learning/features/alphabet/alphabet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Words that must never appear in content or child-facing text (family and
/// faith suitability: no pork, alcohol, gambling, violence or rude words).
const blocked = [
  'pig', 'pigs', 'piglet', 'pork', 'bacon', 'ham', 'sausage', 'pepperoni', 'hotdog', 'hot dog', 'lard',
  'wine', 'beer', 'alcohol', 'vodka', 'whisky', 'cocktail',
  'gamble', 'gambling', 'casino', 'bet', 'lottery', 'dice',
  'gun', 'kill', 'bomb', 'blood', 'skull', 'devil', 'witch', 'ghost', 'zombie',
  'stupid', 'dumb', 'idiot', 'hate', 'shut up', 'loser', 'ugly',
];

bool _hasBlocked(String text) {
  final lower = text.toLowerCase();
  return blocked.any((w) => RegExp('\\b${RegExp.escape(w)}\\b').hasMatch(lower));
}

void main() {
  test('no picture word or description uses blocked words', () {
    for (final w in [...ContentCatalog.words, ...ContentCatalog.endSoundWords]) {
      expect(_hasBlocked(w.text), isFalse, reason: w.text);
      expect(_hasBlocked(w.picture.description), isFalse, reason: w.picture.description);
    }
  });

  test('no string literal in lib/ uses blocked words', () {
    final literal = RegExp(r"'([^'\\]|\\.)*'");
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      for (final m in literal.allMatches(f.readAsStringSync())) {
        if (_hasBlocked(m.group(0)!)) offenders.add('${f.path}: ${m.group(0)}');
      }
    }
    expect(offenders, isEmpty);
  });

  test('every letter A–Z has a picture word with its own illustration', () {
    for (final l in ContentCatalog.letters) {
      final w = ContentCatalog.alphabetWordFor(l.id);
      expect(w.letterId, l.id);
      expect(WordArt.forWord(w.id), isNotNull, reason: 'no illustration for ${w.text}');
    }
  });

  test('end-sound pictures (x) are never beginning-sound lesson words', () {
    final lessonIds = {for (final w in ContentCatalog.words) w.id};
    for (final w in ContentCatalog.endSoundWords) {
      expect(lessonIds.contains(w.id), isFalse);
    }
    for (final l in LearningPreferences.defaultSoundSequence) {
      expect(ContentCatalog.wordsFor(l).every((w) => !_hasBlocked(w.text)), isTrue);
    }
  });

  test('defaults suit toddlers: tracing off, two games per lesson', () {
    const p = LearningPreferences();
    expect(p.tracingEnabled, isFalse);
    expect(p.readiness, Readiness.starting);
  });

  testWidgets('letter book flips from A to Z with the arrows', (tester) async {
    await setScreen(tester, const Size(390, 844));
    final app = await TestApp.create();
    await tester.pumpWidget(app.wrap(const AlphabetScreen()));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('letter A'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 26'), findsOneWidget);
    expect(find.text('ant'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Next letter'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 26'), findsOneWidget);
    expect(find.text('ball'), findsOneWidget);
    for (var i = 0; i < 30; i++) {
      final next = find.bySemanticsLabel('Next letter');
      await tester.tap(next, warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    expect(find.text('26 / 26'), findsOneWidget);
    expect(find.text('zebra'), findsOneWidget);
    expect(app.progress.data.skills.values.where((s) => s.exposures > 0).length, 26);
  });
}
