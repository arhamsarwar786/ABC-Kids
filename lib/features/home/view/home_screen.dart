import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/constants/app_assets.dart';
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
      backgroundColor: Colors.transparent,
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 56), // Placeholder to balance center text
                    const Text(
                      'Learn',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF5D5D5D),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        viewModel.handleNavigation(() {
                          Navigator.pushNamed(context, AppRoutes.settings);
                        });
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7675),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                          ],
                        ),
                        child: const Icon(Icons.settings_rounded, color: Colors.white, size: 32),
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
                        backgroundColor: const Color(0xFFFF7474),
                        buttonColor: const Color(0xFF9C27B0), // Purple
                        title: 'Learn Words',
                        onTap: () {
                          viewModel.handleNavigation(() {
                            Navigator.pushNamed(context, AppRoutes.abc);
                          });
                        },
                        centerGraphic: SizedBox(
                          width: 220,
                          height: 120,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                left: 10,
                                top: 0,
                                child: Transform.rotate(
                                  angle: -0.1,
                                  child: const OutlinedText(
                                    text: 'A',
                                    fontSize: 85,
                                    textColor: Color(0xFFFFD54F),
                                    outlineColor: Color(0xFF7B1FA2),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 85,
                                top: -10,
                                child: Transform.rotate(
                                  angle: 0.1,
                                  child: const OutlinedText(
                                    text: 'B',
                                    fontSize: 75,
                                    textColor: Color(0xFFFFD54F),
                                    outlineColor: Color(0xFF7B1FA2),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 10,
                                top: 15,
                                child: Transform.rotate(
                                  angle: 0.15,
                                  child: const OutlinedText(
                                    text: 'C',
                                    fontSize: 85,
                                    textColor: Color(0xFFFFD54F),
                                    outlineColor: Color(0xFF7B1FA2),
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
                        backgroundColor: const Color(0xFF7FA3FF), // Light Blue
                        buttonColor: const Color(0xFF3F51B5), // Dark Blue
                        title: 'Play Numbers',
                        onTap: () {
                          viewModel.handleNavigation(() {
                            Navigator.pushNamed(context, AppRoutes.counting);
                          });
                        },
                        centerGraphic: const SizedBox(
                          width: 240,
                          height: 110,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                left: 20,
                                child: NumberCircle(numStr: '1', bgColor: Color(0xFFFF5252)),
                              ),
                              Positioned(
                                right: 20,
                                child: NumberCircle(numStr: '3', bgColor: Color(0xFF40C4FF)),
                              ),
                              Positioned(
                                child: NumberCircle(numStr: '2', bgColor: Color(0xFFFFE57F), scale: 1.2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48), // Padding at bottom for scroll safety
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
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
          ],
        ),
        child: Stack(
          children: [
            // Center Graphic elements overlapping beautifully
            Align(
              alignment: const Alignment(0, -0.3),
              child: centerGraphic,
            ),
            
            // Bottom Left Title
            Positioned(
              bottom: 24,
              left: 24,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
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
                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
                  ],
                ),
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 36),
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
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        numStr,
        style: TextStyle(
          fontSize: 50 * scale,
          color: numStr == '2' ? Colors.black87 : Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
