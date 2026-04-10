import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/constants/app_assets.dart';
import '../../shared/widgets/letter_tile.dart';
import '../viewmodel/learning_viewmodel.dart';

class AbcScreen extends StatefulWidget {
  const AbcScreen({super.key});

  @override
  State<AbcScreen> createState() => _AbcScreenState();
}

class _AbcScreenState extends State<AbcScreen> {
  late AudioService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = context.read<AudioService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioService.stopBackgroundMusic();
    });
  }

  @override
  void dispose() {
    _audioService.playBackgroundMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letters = context.read<LearningViewModel>().alphabets;
    final colors = [
      AppTheme.accentPink,
      AppTheme.accentGreen,
      AppTheme.primaryColor,
      AppTheme.secondaryColor
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('ABC Learning'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.appBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: letters.length,
            itemBuilder: (context, index) {
              return LetterTile(
                label: letters[index].label,
                backgroundColor: colors[index % colors.length],
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.detail,
                    arguments: letters[index],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
