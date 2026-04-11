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

              const Spacer(flex: 3),

              // 2. Navigation Control Center (Bottom)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 160,
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

    const cornerRadius = 15.0;
    final path = Path();

    if (isLeft) {
      // Rounded Left-pointing triangle
      path.moveTo(size.width, cornerRadius);
      path.quadraticBezierTo(size.width, 0, size.width - cornerRadius, 5);
      path.lineTo(cornerRadius, size.height / 2 - 5);
      path.quadraticBezierTo(
        0,
        size.height / 2,
        cornerRadius,
        size.height / 2 + 5,
      );
      path.lineTo(size.width - cornerRadius, size.height - 5);
      path.quadraticBezierTo(
        size.width,
        size.height,
        size.width,
        size.height - cornerRadius,
      );
    } else {
      // Rounded Right-pointing triangle
      path.moveTo(0, cornerRadius);
      path.quadraticBezierTo(0, 0, cornerRadius, 5);
      path.lineTo(size.width - cornerRadius, size.height / 2 - 5);
      path.quadraticBezierTo(
        size.width,
        size.height / 2,
        size.width - cornerRadius,
        size.height / 2 + 5,
      );
      path.lineTo(cornerRadius, size.height - 5);
      path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);
    }
    path.close();

    // Draw shadow first
    canvas.drawShadow(path.shift(const Offset(0, 4)), AppColors.black26, 6, true);
    canvas.drawPath(path, paint);

    // Draw white border for professional look
    final borderPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
