import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/learning_item.dart';
import '../viewmodel/learning_viewmodel.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/constants/app_assets.dart';
import '../../shared/widgets/sound_button.dart';

class DetailScreen extends StatefulWidget {
  final LearningItem item;
  const DetailScreen({super.key, required this.item});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late LearningItem _currentItem;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
    _playSound();
  }

  void _playSound() {
    context.read<AudioService>().playSound(_currentItem.audioFileName);
  }

  void _goToPrevious() {
    final viewModel = context.read<LearningViewModel>();
    List<LearningItem> list = _isAlphabet()
        ? viewModel.alphabets
        : viewModel.numbers;
    int index = list.indexWhere((item) => item.label == _currentItem.label);

    if (index > 0) {
      setState(() {
        _currentItem = list[index - 1];
      });
      _playSound();
    }
  }

  void _goToNext() {
    final viewModel = context.read<LearningViewModel>();
    List<LearningItem> list = _isAlphabet()
        ? viewModel.alphabets
        : viewModel.numbers;
    int index = list.indexWhere((item) => item.label == _currentItem.label);

    if (index < list.length - 1) {
      setState(() {
        _currentItem = list[index + 1];
      });
      _playSound();
    }
  }

  bool _isAlphabet() {
    return double.tryParse(_currentItem.label) == null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text('Learn ${_currentItem.label}')),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.appBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 250,
                  width: 250,
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    elevation: 8,
                    child: Center(
                      child: Text(
                        _currentItem.label,
                        style: TextStyle(
                          fontSize: 120,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: _goToPrevious,
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 48),
                      color: Theme.of(context).primaryColor,
                    ),
                    SoundButton(onPressed: _playSound),
                    IconButton(
                      onPressed: _goToNext,
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 48,
                      ),
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
