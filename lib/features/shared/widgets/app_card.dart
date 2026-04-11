import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';

class AppCard extends StatelessWidget {
  final String title;
  final String buttonText;
  final VoidCallback onTap;
  final Color titleColor;

  const AppCard({
    super.key,
    required this.title,
    required this.buttonText,
    required this.onTap,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: onTap,
                    child: Text(buttonText),
                  ),
                ],
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 64,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
