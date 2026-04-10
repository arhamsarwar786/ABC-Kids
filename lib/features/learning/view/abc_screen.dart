import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
      AppTheme.secondaryColor,
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'The Alphabet',
          style: GoogleFonts.fredoka(
            color: const Color(0xFF5D5D5D),
            fontWeight: FontWeight.w900,
            fontSize: 28,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB57AFF), Color(0xFF7A4BFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
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
