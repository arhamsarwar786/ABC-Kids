import 'package:abc_kids_learning/core/design/art/stroke_painter.dart';
import 'package:abc_kids_learning/data/content/letter_strokes.dart';
import 'package:abc_kids_learning/data/models/content.dart';
import 'package:abc_kids_learning/data/models/progress.dart';
import 'package:abc_kids_learning/engine/activity_engine.dart';
import 'package:abc_kids_learning/features/games/game_framework.dart';
import 'package:abc_kids_learning/features/games/game_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Every game reaches completion and records evidence in its own domain.
void main() {
  final cases = <GameSpec, SkillDomain>{
    const GameSpec(type: GameType.pop, letters: ['m', 's'], showIntroDemo: false): SkillDomain.visualMatching,
    const GameSpec(type: GameType.feedMonster, letters: ['m', 'a'], showIntroDemo: false): SkillDomain.beginningSound,
    const GameSpec(type: GameType.safari, letters: ['m'], level: 0, showIntroDemo: false): SkillDomain.wordPicture,
    const GameSpec(type: GameType.safari, letters: ['t'], level: 1, showIntroDemo: false): SkillDomain.beginningSound,
    const GameSpec(type: GameType.parking, letters: ['p'], level: 0, showIntroDemo: false): SkillDomain.visualMatching,
    const GameSpec(type: GameType.parking, letters: ['n'], level: 1, showIntroDemo: false): SkillDomain.caseMatching,
    const GameSpec(type: GameType.buildLetter, letters: ['m', 'a', 'i'], showIntroDemo: false): SkillDomain.construction,
    const GameSpec(type: GameType.magicTrail, letters: ['s', 't'], showIntroDemo: false): SkillDomain.tracing,
    const GameSpec(type: GameType.countMatch, letters: ['1'], showIntroDemo: false): SkillDomain.number,
    const GameSpec(type: GameType.shapeMatch, letters: ['x'], showIntroDemo: false): SkillDomain.shapeMatching,
    const GameSpec(type: GameType.shapeName, letters: ['x'], showIntroDemo: false): SkillDomain.shapeNaming,
  };

  for (final c in cases.entries) {
    testWidgets('${c.key.type.name} level ${c.key.level} completes', (tester) async {
      await setScreen(tester, const Size(390, 844));
      final app = await TestApp.create();
      GameResult? result;
      await tester.pumpWidget(app.wrap(buildGame(c.key, (r) => result = r)));
      await settleFor(tester, const Duration(milliseconds: 300));
      final state = tester.state<GameState>(find.byWidgetPredicate((w) => w is GameWidget));
      for (var guard = 0; guard < 20 && result == null; guard++) {
        final e = state.engine;
        if (e.acceptsInput) {
          e.round.choices.isEmpty ? e.completeTask() : e.choose(e.round.answer);
        }
        await settleFor(tester, const Duration(milliseconds: 1300));
      }
      expect(result?.completed, isTrue);
      expect(state.engine.state, EngineState.completed);
      final attempts = app.progress.data.attempts.where((a) => a.gameType == c.key.type).toList();
      expect(attempts, isNotEmpty);
      expect(attempts.every((a) => a.domain == c.value), isTrue, reason: '${attempts.map((a) => a.domain)}');
      expect(attempts.every((a) => a.outcome.isIndependent), isTrue);
      await settleFor(tester, const Duration(seconds: 1));
    });
  }

  testWidgets('Build a Letter: tap a piece, then tap its place; finishes automatically', (tester) async {
    await setScreen(tester, const Size(390, 844));
    final app = await TestApp.create();
    GameResult? result;
    await tester.pumpWidget(app.wrap(buildGame(const GameSpec(type: GameType.buildLetter, letters: ['i'], showIntroDemo: false), (r) => result = r)));
    await settleFor(tester, const Duration(milliseconds: 300));
    final outline = tester.getRect(find.bySemanticsLabel(RegExp(r'^letter i outline')));
    final frame = LetterFrame(LetterStrokeLibrary.all['i']!.strokes, outline.size);
    Offset at(double x, double y) => outline.topLeft + frame.toLocal(Offset(x, y));

    // Wrong place for the stem (far corner) is rejected; nothing is placed.
    await tester.tap(find.bySemanticsLabel('letter piece 1'));
    await tester.pump();
    await tester.tapAt(outline.topLeft + const Offset(4, 4));
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp(r'0 of 2 pieces placed')), findsOneWidget);

    await tester.tapAt(at(0.5, 0.575));
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp(r'1 of 2 pieces placed')), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('letter piece 2'));
    await tester.pump();
    await tester.tapAt(at(0.5, 0.26));
    await settleFor(tester, const Duration(milliseconds: 1500));
    expect(result?.completed, isTrue);
    final a = app.progress.data.attempts.single;
    expect(a.domain, SkillDomain.construction);
    expect(a.outcome, AttemptOutcome.completed);
  });
}
