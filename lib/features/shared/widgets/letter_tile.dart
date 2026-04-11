import 'package:flutter/material.dart';

class LetterTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;

  const LetterTile({
    super.key,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNumber = double.tryParse(label) != null;
    final String assetPath = isNumber
        ? 'assets/images/123_numbers/$label.png'
        : 'assets/images/abc_letters/${label.toLowerCase()}.png';

    return Card(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
