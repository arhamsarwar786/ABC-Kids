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
            fit: BoxFit.fitHeight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),

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
                              fontSize: 30,
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
                                const TextSpan(
                                  text: 'Welcome back to the ',
                                  style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextSpan(
                                  text: 'ABC Kids',
                                  style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
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
                        width: 60,
                        height: 60,
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

              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // ABC Card
                      CategoryCard(
                        gradientColors: const [
                          Color(0xFFFF9A9E),
                          Color(0xFFFECFEF),
                        ], // Cute Pink Gradient
                        buttonColor: Colors.white,
                        buttonIconColor: const Color(0xFFFF9A9E),
                        title: 'Learn Alphabets',
                        onTap: () {
                          viewModel.handleNavigation(() {
                            Navigator.pushNamed(context, AppRoutes.abc);
                          });
                        },

                        centerGraphic: SizedBox(
                          width: 280,
                          height: 200,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                left: 0,
                                top: 10,
                                child: Transform.rotate(
                                  angle: -0.15,
                                  child: Image.asset(
                                    'assets/images/home-page-characters/home-a.png',
                                    height: 120,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 88,
                                top: -18,
                                child: Transform.rotate(
                                  angle: 0.05,
                                  child: Image.asset(
                                    'assets/images/home-page-characters/home-b.png',
                                    height: 110,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 15,
                                child: Transform.rotate(
                                  angle: 0.2,
                                  child: Image.asset(
                                    'assets/images/home-page-characters/home-c.png',
                                    height: 120,
                                    fit: BoxFit.contain,
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
                        gradientColors: const [
                          Color(0xFF84FAB0),
                          Color(0xFF8FD3F4),
                        ], // Fresh Green to Blue Gradient
                        buttonColor: Colors.white,
                        buttonIconColor: const Color(0xFF84FAB0),
                        title: 'Play Numbers',
                        onTap: () {
                          viewModel.handleNavigation(() {
                            Navigator.pushNamed(context, AppRoutes.counting);
                          });
                        },
                        centerGraphic: SizedBox(
                          width: 280,
                          height: 200,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                top: -10,
                                child: Image.asset(
                                  'assets/images/home-page-characters/home-2.png',
                                  height: 110,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                left: 10,
                                bottom: 50,
                                child: Transform.rotate(
                                  angle: -0.1,
                                  child: Image.asset(
                                    'assets/images/home-page-characters/home-1.png',
                                    height: 120,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 10,
                                bottom: 55,
                                child: Transform.rotate(
                                  angle: 0.1,
                                  child: Image.asset(
                                    'assets/images/home-page-characters/home-3.png',
                                    height: 120,
                                    fit: BoxFit.contain,
                                  ),
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
  final List<Color> gradientColors;
  final Widget centerGraphic;
  final String title;
  final Color buttonColor;
  final Color buttonIconColor;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.gradientColors,
    required this.centerGraphic,
    required this.title,
    required this.buttonColor,
    required this.buttonIconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 230,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Decorative background circles
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),

            // Center Graphic elements overlapping beautifully
            Align(alignment: Alignment.center, child: centerGraphic),

            // Bottom Left Title
            Positioned(
              bottom: 15,
              left: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // Bottom Right Next Arrow Button
            Positioned(
              bottom: 16,
              right: 10,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: buttonColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: buttonIconColor,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//NOt Used
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
          BoxShadow(
            color: AppColors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
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
