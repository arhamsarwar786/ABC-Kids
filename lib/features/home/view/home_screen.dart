import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/utils/app_colors.dart';
import '../viewmodel/home_viewmodel.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioService>().playBackgroundMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.appBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Home',
                            style: GoogleFonts.fredoka(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: AppColors.grey,
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: AppColors.grey.withOpacity(0.7),
                              ),
                              children: [
                                const TextSpan(text: 'Welcome back to the '),
                                TextSpan(
                                  text: 'ABC Kids',
                                  style: TextStyle(
                                    color: AppColors.softRed,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        viewModel.handleNavigation(() {
                          Navigator.pushNamed(context, AppRoutes.settings);
                        });
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.softRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 4),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.settings_rounded,
                          color: AppColors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // ABC Card
                      CategoryCard(
                        backgroundColor: AppColors.lightBlue, // Light Blue
                        buttonColor: AppColors.purple, // Purple
                        title: 'Learn Words',
                        onTap: () {
                          viewModel.handleNavigation(() {
                            Navigator.pushNamed(context, AppRoutes.abc);
                          });
                        },
                        centerGraphic: SizedBox(
                          width: 260,
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                left: -6,
                                top: 22,
                                child: Transform.rotate(
                                  angle: -0.1,
                                  child: Image.asset(
                                    'assets/images/abc_letters/a.png',
                                    height: 130,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 75,
                                top: -6,
                                child: Transform.rotate(
                                  angle: 0.1,
                                  child: Image.asset(
                                    'assets/images/abc_letters/b.png',
                                    height: 120,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -6,
                                top: 24,
                                child: Transform.rotate(
                                  angle: 0.15,
                                  child: Image.asset(
                                    'assets/images/abc_letters/c.png',
                                    height: 130,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 123 Card
                      CategoryCard(
                        backgroundColor: AppColors.lightBlue, // Light Blue
                        buttonColor: AppColors.purple, // Dark Blue
                        title: 'Play Numbers',
                        onTap: () {
                          viewModel.handleNavigation(() {
                            Navigator.pushNamed(context, AppRoutes.counting);
                          });
                        },
                        centerGraphic: SizedBox(
                          width: 260,
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                top: 0,
                                child: Image.asset(
                                  'assets/images/123_numbers/2.png',
                                  height: 120,
                                ),
                              ),
                              Positioned(
                                left: 5,
                                bottom: 40,
                                child: Image.asset(
                                  'assets/images/123_numbers/1.png',
                                  height: 130,
                                ),
                              ),
                              Positioned(
                                right: 5,
                                bottom: 45,
                                child: Image.asset(
                                  'assets/images/123_numbers/3.png',
                                  height: 130,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 48,
                      ), // Padding at bottom for scroll safety
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Supporting Specialized UI Widgets ---

class CategoryCard extends StatelessWidget {
  final Color backgroundColor;
  final Widget centerGraphic;
  final String title;
  final Color buttonColor;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.backgroundColor,
    required this.centerGraphic,
    required this.title,
    required this.buttonColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 230,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: AppColors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Center Graphic elements overlapping beautifully
            Align(alignment: const Alignment(0, -0.3), child: centerGraphic),

            // Bottom Left Title
            Positioned(
              bottom: 24,
              left: 24,
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            // Bottom Right Next Arrow Button
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: buttonColor,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.white,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OutlinedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color textColor;
  final Color outlineColor;

  const OutlinedText({
    super.key,
    required this.text,
    required this.fontSize,
    required this.textColor,
    required this.outlineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Outline mapping
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            fontFamily: 'Comic Sans MS',
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 14
              ..color = outlineColor
              ..strokeJoin = StrokeJoin.round,
          ),
        ),
        // Fill mapping
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            fontFamily: 'Comic Sans MS',
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class NumberCircle extends StatelessWidget {
  final String numStr;
  final Color bgColor;
  final double scale;

  const NumberCircle({
    super.key,
    required this.numStr,
    required this.bgColor,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90 * scale,
      height: 90 * scale,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 4),
        boxShadow: const [
          BoxShadow(color: AppColors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        numStr,
        style: TextStyle(
          fontSize: 50 * scale,
          color: numStr == '2' ? AppColors.black87 : AppColors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
