import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/app_icons.dart';

class AdPromptDialog {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String watchLabel,
    required String skipLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: AppTokens.navy,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTokens.navy,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                skipLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppTokens.navy,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(watchLabel),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showUnavailable(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            'Try again soon',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: AppTokens.navy,
            ),
          ),
          content: Text(
            'A video is not ready right now. Keep learning and try again later!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTokens.navy,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showStarEarned(BuildContext context, int totalStars) {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            'You earned a star!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: AppTokens.navy,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.star, color: Color(0xFFFFB74D), size: 64),
              const SizedBox(height: 12),
              Text(
                'You now have $totalStars ${totalStars == 1 ? 'star' : 'stars'}!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTokens.navy,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Yay!'),
            ),
          ],
        );
      },
    );
  }
}
