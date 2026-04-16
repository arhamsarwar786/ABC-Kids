import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/learning_item.dart';
import '../viewmodel/learning_viewmodel.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/utils/app_colors.dart';

class DetailScreen extends StatefulWidget {
  final LearningItem item;
  const DetailScreen({super.key, required this.item});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late LearningItem _currentItem;
  late AudioService _audioService;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
    _audioService = context.read<AudioService>();
    _playSound();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioService.setBgmSuspended(true);
    });
  }

  void _playSound() {
    context.read<AudioService>().playSound(_currentItem.audioFileName);
  }

  void _showSpeedDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Speed",
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return Transform.scale(
          scale: Tween(begin: 0.85, end: 1.0).evaluate(curved),
          child: Opacity(
            opacity: animation.value,
            child: Center(child: _SpeedPopupContent()),
          ),
        );
      },
    );
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

  @override
  void dispose() {
    _audioService.setBgmSuspended(false);
    super.dispose();
  }

  bool _isAlphabet() {
    return double.tryParse(_currentItem.label) == null;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LearningViewModel>();
    List<LearningItem> list = _isAlphabet()
        ? viewModel.alphabets
        : viewModel.numbers;
    int index = list.indexWhere((item) => item.label == _currentItem.label);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.transparent,
      appBar: AppBar(
        title: Text(
          "Let's Learn",
          style: GoogleFonts.fredoka(
            color: AppColors.grey,
            fontWeight: FontWeight.w900,
            fontSize: 32,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.transparent,
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

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _showSpeedDialog,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.speed, color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
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
              const Spacer(flex: 2),

              // 1. Giant 3D Styled Character
              GestureDetector(
                onTap: _playSound,
                child: Center(
                  child: Hero(
                    tag: 'item_${_currentItem.label}',
                    child: Chunky3DText(text: _currentItem.label),
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // 2. Pronunciation Speed Controller
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 40),
              //   child: Column(
              //     children: [
              //       Row(
              //         mainAxisAlignment: MainAxisAlignment.center,
              //         children: [
              //           const Icon(
              //             Icons.speed,
              //             color: AppColors.grey,
              //             size: 20,
              //           ),
              //           const SizedBox(width: 10),
              //           Text(
              //             "Pronunciation Speed",
              //             style: GoogleFonts.fredoka(
              //               color: AppColors.grey,
              //               fontWeight: FontWeight.w600,
              //               fontSize: 18,
              //             ),
              //           ),
              //         ],
              //       ),
              //       Consumer<AudioService>(
              //         builder: (context, audioService, child) {
              //           return SliderTheme(
              //             data: SliderTheme.of(context).copyWith(
              //               activeTrackColor: AppColors.gradientStart,
              //               inactiveTrackColor: AppColors.gradientStart
              //                   .withOpacity(0.2),
              //               thumbColor: AppColors.gradientEnd,
              //               overlayColor: AppColors.gradientEnd.withOpacity(
              //                 0.2,
              //               ),
              //               trackHeight: 10,
              //               valueIndicatorColor: AppColors.gradientEnd,
              //               valueIndicatorTextStyle: GoogleFonts.fredoka(
              //                 color: AppColors.white,
              //                 fontWeight: FontWeight.bold,
              //               ),
              //               thumbShape: const RoundSliderThumbShape(
              //                 enabledThumbRadius: 12,
              //                 elevation: 4,
              //               ),
              //             ),
              //             child: Slider(
              //               value: audioService.playbackRate,
              //               min: 0.5,
              //               max: 2.0,
              //               divisions: 6,
              //               label: "${audioService.playbackRate}x",
              //               onChanged: (value) {
              //                 audioService.setPlaybackRate(value);
              //               },
              //             ),
              //           );
              //         },
              //       ),
              //     ],
              //   ),
              // ),
              const Spacer(flex: 2),

              // 3. Navigation Control Center (Bottom)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 150,
                  left: 30,
                  right: 30,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous Button (Hidden if first)
                    SizedBox(
                      width: 80,
                      height: 70,
                      child: index > 0
                          ? GradientTriangleButton(
                              direction: AxisDirection.left,
                              onTap: _goToPrevious,
                            )
                          : null,
                    ),

                    // Sound Button (Professional Circular Gradient)
                    GestureDetector(
                      onTap: _playSound,
                      child: Center(
                        child: Text(
                          _currentItem.label,
                          style: GoogleFonts.fredoka(
                            color: AppColors.purpleText,
                            fontSize: 110,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // Next Button (Hidden if last)
                    SizedBox(
                      width: 80,
                      height: 70,
                      child: index < list.length - 1
                          ? GradientTriangleButton(
                              direction: AxisDirection.right,
                              onTap: _goToNext,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//
class _SpeedPopupContent extends StatefulWidget {
  const _SpeedPopupContent();

  @override
  State<_SpeedPopupContent> createState() => _SpeedPopupContentState();
}

class _SpeedPopupContentState extends State<_SpeedPopupContent> {
  late double tempSpeed;
  late double originalSpeed;

  @override
  void initState() {
    super.initState();

    final audio = context.read<AudioService>();

    originalSpeed = audio.playbackRate;
    tempSpeed = originalSpeed;
  }

  /// preview pronunciation when user releases slider
  void _preview(AudioService audio) {
    audio.setPlaybackRate(tempSpeed);

    /// play once for preview
    audio.playCurrent(); // ⚠️ see NOTE below
  }

  void _save(AudioService audio) {
    audio.setPlaybackRate(tempSpeed);
    Navigator.pop(context);
  }

  void _cancel(AudioService audio) {
    audio.setPlaybackRate(originalSpeed);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.read<AudioService>();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 360,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withOpacity(.35),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// HEADER
            Row(
              children: const [
                Icon(Icons.speed, color: AppColors.white, size: 30),
                SizedBox(width: 12),
                Text(
                  "Pronunciation Speed",
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// GLASS CARD
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  /// SPEED TEXT
                  Text(
                    "${tempSpeed.toStringAsFixed(1)}x",
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// SLIDER
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.white,
                      inactiveTrackColor: AppColors.white.withOpacity(.25),
                      thumbColor: AppColors.white,
                      overlayColor: AppColors.white.withOpacity(.15),
                      trackHeight: 9,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 14,
                      ),
                    ),
                    child: Slider(
                      value: tempSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 6,

                      /// move only local value
                      onChanged: (value) {
                        setState(() => tempSpeed = value);
                      },

                      /// ⭐ PROFESSIONAL BEHAVIOR
                      onChangeEnd: (_) {
                        _preview(audio);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// ACTION BUTTONS
            Row(
              children: [
                /// CANCEL
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _cancel(audio),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.white),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                /// SAVE
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _save(audio),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.gradientStart,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Specialized UI Widgets for Detail Screen ---
class Chunky3DText extends StatelessWidget {
  final String text;
  const Chunky3DText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final bool isNumber = double.tryParse(text) != null;
    final String assetPath = isNumber
        ? 'assets/images/123_numbers/$text.png'
        : 'assets/images/abc_letters/${text.toLowerCase()}.png';

    return Image.asset(assetPath, height: 300, fit: BoxFit.contain);
  }
}

class GradientTriangleButton extends StatelessWidget {
  final AxisDirection direction;
  final VoidCallback onTap;

  const GradientTriangleButton({
    super.key,
    required this.direction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = direction == AxisDirection.left;

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: TrianglePainter(isLeft: isLeft),
        child: Container(
          width: 80,
          height: 80,
          alignment: isLeft
              ? const Alignment(0.2, 0)
              : const Alignment(-0.2, 0),
          child: Icon(
            isLeft
                ? Icons.arrow_back_ios_new_rounded
                : Icons.arrow_forward_ios_rounded,
            color: AppColors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Triangle Button
class TrianglePainter extends CustomPainter {
  final bool isLeft;
  TrianglePainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.gradientStart, AppColors.gradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    const r = 18.0; // corner radius

    final path = Path();

    if (isLeft) {
      // TOP RIGHT rounded
      path.moveTo(size.width, r);
      path.quadraticBezierTo(size.width, 0, size.width - r, 0);

      // go to arrow tip upper
      path.lineTo(r + 6, size.height / 2 - r);

      // ⭐ ROUNDED ARROW TIP
      path.quadraticBezierTo(0, size.height / 2, r + 6, size.height / 2 + r);

      // bottom line
      path.lineTo(size.width - r, size.height);

      // BOTTOM RIGHT rounded
      path.quadraticBezierTo(
        size.width,
        size.height,
        size.width,
        size.height - r,
      );
    } else {
      // TOP LEFT rounded
      path.moveTo(0, r);
      path.quadraticBezierTo(0, 0, r, 0);

      // go to arrow tip upper
      path.lineTo(size.width - r - 6, size.height / 2 - r);

      // ⭐ ROUNDED ARROW TIP
      path.quadraticBezierTo(
        size.width,
        size.height / 2,
        size.width - r - 6,
        size.height / 2 + r,
      );

      // bottom line
      path.lineTo(r, size.height);

      // BOTTOM LEFT rounded
      path.quadraticBezierTo(0, size.height, 0, size.height - r);
    }

    path.close();

    // shadow
    canvas.drawShadow(
      path.shift(const Offset(0, 4)),
      AppColors.black26,
      6,
      true,
    );

    // fill
    canvas.drawPath(path, paint);

    // border
    final borderPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
