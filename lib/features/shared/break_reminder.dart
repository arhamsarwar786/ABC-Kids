import 'package:flutter/material.dart';

import '../../core/design/art/art_kit.dart';
import '../../core/design/art/characters.dart';
import '../../core/design/components/buttons.dart';
import '../../core/design/app_icons.dart';

/// Gentle active-time reminder shown at a natural break. Returns true to keep
/// playing. There is no hard limit and no countdown.
Future<bool> showBreakReminder(BuildContext context) async {
  final r = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Art(MascotArt(bear: true), size: 110),
        const SizedBox(height: 12),
        Text('Time for a little break?', style: Theme.of(ctx).textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('You have been playing for a while. You can stop here or keep going.',
            style: Theme.of(ctx).textTheme.bodyLarge, textAlign: TextAlign.center),
      ]),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        PrimaryButton(label: 'Finish for now', icon: AppIcons.home, onPressed: () => Navigator.pop(ctx, false)),
        SecondaryButton(label: 'Keep playing', onPressed: () => Navigator.pop(ctx, true)),
      ],
    ),
  );
  return r ?? true;
}
