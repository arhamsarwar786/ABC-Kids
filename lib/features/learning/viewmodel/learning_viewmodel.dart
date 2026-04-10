import 'package:flutter/material.dart';
import '../model/learning_item.dart';
import '../../../core/constants/app_assets.dart';

class LearningViewModel extends ChangeNotifier {
  final List<LearningItem> _alphabets = AlphabetAudioAssets.letters.entries.map(
    (e) => LearningItem(
      label: e.key.toUpperCase(),
      audioFileName: e.value,
    ),
  ).toList();

  final List<LearningItem> _numbers = CountingAudioAssets.numbers.entries.map(
    (e) => LearningItem(
      label: e.key.toString(),
      audioFileName: e.value,
    ),
  ).toList();

  List<LearningItem> get alphabets => _alphabets;
  List<LearningItem> get numbers => _numbers;
}
