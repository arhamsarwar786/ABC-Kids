import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  label,
                  style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontSize:
                        110, // Large base size for FittedBox to scale down
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(2, 4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
