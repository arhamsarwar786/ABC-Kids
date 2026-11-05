import 'package:abc_kids_learning/data/models/content.dart';
import 'package:abc_kids_learning/features/alphabet/alphabet_screen.dart';
import 'package:abc_kids_learning/features/games/game_framework.dart';
import 'package:abc_kids_learning/features/games/game_launcher.dart';
import 'package:abc_kids_learning/features/games/games_catalogue.dart';
import 'package:abc_kids_learning/features/lesson/lesson_screen.dart';
import 'package:abc_kids_learning/data/models/progress.dart';
import 'package:abc_kids_learning/features/numbers/numbers_hub.dart';
import 'package:abc_kids_learning/features/parent/device_settings_screen.dart';
import 'package:abc_kids_learning/features/parent/info_screens.dart';
import 'package:abc_kids_learning/features/parent/learners_screen.dart';
import 'package:abc_kids_learning/features/parent/parent_dashboard.dart';
import 'package:abc_kids_learning/features/parent/preferences_screen.dart';
import 'package:abc_kids_learning/features/parent/progress_details_screen.dart';
import 'package:abc_kids_learning/features/shapes/shapes_hub.dart';
import 'package:abc_kids_learning/features/shell/main_shell.dart';
import 'package:abc_kids_learning/features/sound_path/sound_path_screen.dart';
import 'package:abc_kids_learning/features/stickers/stickers_tab.dart';
import 'package:abc_kids_learning/features/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const sizes = {
  'small phone 320x568': Size(320, 568),
  'phone 390x844': Size(390, 844),
  'tablet 1024x1366': Size(1024, 1366),
};

final screens = <String, Widget Function()>{
  'welcome': () => const WelcomeScreen(),
  'shell/home': () => const MainShell(),
  'sound path': () => const SoundPathScreen(),
  'alphabet': () => const AlphabetScreen(),
  'games catalogue': () => const GamesCatalogue(),
  'letter book a': () => const LetterBookScreen(),
  'letter book x': () => const LetterBookScreen(startIndex: 23),
  'letter book s (play button)': () => const LetterBookScreen(startIndex: 18),
  'letter book w': () => const LetterBookScreen(startIndex: 22),
  'stickers': () => const StickersTab(),
  'numbers hub': () => const NumbersHub(),
  'number explorer': () => const NumberExplorer(),
  'shapes hub': () => const ShapesHub(),
  'shape explorer': () => const ShapeExplorer(),
  'lesson intro m': () => const LessonScreen(
          plan: LessonPlan(letterId: 'm', distractorLetterIds: [], steps: [
        LessonStep(LessonStepKind.introduction),
        LessonStep(LessonStepKind.completion),
      ])),
  'lesson discovery m': () => const LessonScreen(
      startStep: 1,
      plan: LessonPlan(letterId: 'm', distractorLetterIds: [], steps: [
        LessonStep(LessonStepKind.introduction),
        LessonStep(LessonStepKind.pictureDiscovery),
        LessonStep(LessonStepKind.completion),
      ])),
  'lesson intro x': () => const LessonScreen(
          plan: LessonPlan(letterId: 'x', distractorLetterIds: [], steps: [
        LessonStep(LessonStepKind.introduction),
        LessonStep(LessonStepKind.completion),
      ])),
  'lesson discovery w': () => const LessonScreen(
      startStep: 1,
      plan: LessonPlan(letterId: 'w', distractorLetterIds: [], steps: [
        LessonStep(LessonStepKind.introduction),
        LessonStep(LessonStepKind.pictureDiscovery),
        LessonStep(LessonStepKind.completion),
      ])),
  'lesson discovery x': () => const LessonScreen(
      startStep: 1,
      plan: LessonPlan(letterId: 'x', distractorLetterIds: [], steps: [
        LessonStep(LessonStepKind.introduction),
        LessonStep(LessonStepKind.pictureDiscovery),
        LessonStep(LessonStepKind.completion),
      ])),
  'lesson completion m': () => const LessonScreen(
      startStep: 1,
      plan: LessonPlan(letterId: 'm', distractorLetterIds: [], steps: [
        LessonStep(LessonStepKind.introduction),
        LessonStep(LessonStepKind.completion),
      ])),
  'parent dashboard': () => const ParentDashboard(),
  'learners': () => const LearnersScreen(),
  'preferences': () => const PreferencesScreen(),
  'device settings': () => const DeviceSettingsScreen(),
  'progress details': () => const ProgressDetailsScreen(),
  'content status': () => const ContentStatusScreen(),
  'privacy': () => const PrivacyScreen(),
  'help': () => const HelpScreen(),
};

final games = <GameSpec>[
  const GameSpec(type: GameType.pop, letters: ['m', 's'], distractors: ['a']),
  const GameSpec(type: GameType.feedMonster, letters: ['m'], distractors: ['s']),
  const GameSpec(type: GameType.safari, letters: ['m'], level: 0),
  const GameSpec(type: GameType.safari, letters: ['s'], level: 1),
  const GameSpec(type: GameType.parking, letters: ['m'], level: 0),
  const GameSpec(type: GameType.parking, letters: ['a'], level: 1),
  const GameSpec(type: GameType.buildLetter, letters: ['m', 'i']),
  const GameSpec(type: GameType.magicTrail, letters: ['m']),
  const GameSpec(type: GameType.countMatch, letters: ['1']),
  const GameSpec(type: GameType.shapeMatch, letters: ['x']),
  const GameSpec(type: GameType.shapeName, letters: ['x']),
];

void main() {
  for (final size in sizes.entries) {
    for (final scale in [1.0, 2.0]) {
      group('${size.key} text x$scale', () {
        for (final s in screens.entries) {
          testWidgets(s.key, (tester) async {
            await setScreen(tester, size.value, textScale: scale);
            final app = await TestApp.create(prefs: {'onboarding_seen': true});
            await tester.pumpWidget(app.wrap(s.value()));
            await settleFor(tester, const Duration(milliseconds: 600));
            expect(tester.takeException(), isNull);
          });
        }
        for (final g in games) {
          testWidgets('game ${g.type.name} level ${g.level}', (tester) async {
            await setScreen(tester, size.value, textScale: scale);
            final app = await TestApp.create();
            await tester.pumpWidget(app.wrap(buildGame(g, (_) {})));
            await settleFor(tester, const Duration(milliseconds: 400));
            expect(tester.takeException(), isNull, reason: 'demo');
            if (find.text('I’m ready').evaluate().isNotEmpty) {
              await tester.tap(find.text('I’m ready'));
              await settleFor(tester, const Duration(milliseconds: 400));
            }
            expect(tester.takeException(), isNull);
          });
        }
      });
    }
  }

  testWidgets('child touch targets are at least 56px', (tester) async {
    await setScreen(tester, const Size(390, 844));
    final app = await TestApp.create();
    await tester.pumpWidget(app.wrap(buildGame(const GameSpec(type: GameType.parking, letters: ['m'], showIntroDemo: false), (_) {})));
    await settleFor(tester, const Duration(milliseconds: 400));
    await expectLater(tester, meetsGuideline(const MinimumTapTargetGuideline(size: Size(56, 56), link: '')));
  });

  testWidgets('child screens meet Android tap target and text contrast guidelines', (tester) async {
    await setScreen(tester, const Size(390, 844));
    final app = await TestApp.create(prefs: {'onboarding_seen': true});
    await tester.pumpWidget(app.wrap(const MainShell()));
    await settleFor(tester, const Duration(milliseconds: 400));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
