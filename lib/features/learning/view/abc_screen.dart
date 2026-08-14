import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/ads_service.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/utils/app_colors.dart';
import '../../shared/widgets/banner_ad_widget.dart';
import '../../shared/widgets/letter_tile.dart';
import '../viewmodel/learning_viewmodel.dart';

class AbcScreen extends StatefulWidget {
  const AbcScreen({super.key});

  @override
  State<AbcScreen> createState() => _AbcScreenState();
}

class _AbcScreenState extends State<AbcScreen> {
  bool _isLeaving = false;

  Future<void> _leave() async {
    if (_isLeaving) return;
    _isLeaving = true;
    await context.read<AdsService>().showInterstitialAtSessionEnd();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final letters = context.read<LearningViewModel>().alphabets;
    final colors = [
      const Color(0xFFFF7675), // Soft Red
      const Color(0xFF7FA3FF), // Light Blue
      const Color(0xFF81C784), // Green
      const Color(0xFFFFB74D), // Orange
      const Color(0xFFBA68C8), // Medium Purple
      const Color(0xFFF06292), // Pink
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _leave();
      },
      child: Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.transparent,
      bottomNavigationBar: const AppBannerAd(),
      appBar: AppBar(
        title: Text(
          'The Alphabet',
          style: GoogleFonts.fredoka(
            color: AppColors.grey,
            fontWeight: FontWeight.w900,
            fontSize: 28,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: GestureDetector(
              onTap: _leave,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.white,
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
    ),
    );
  }
}
