import 'package:flutter/material.dart';

import '../tokens.dart';
import 'chunky.dart';
import '../app_icons.dart';

/// Round chunky icon button with a 56px+ target and a spoken semantics label.
class ChildIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final double size;

  const ChildIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.background = AppTokens.surface,
    this.foreground = AppTokens.purple,
    this.size = AppTokens.childTarget,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      label: label,
      enabled: enabled,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Chunky(
            circle: true,
            onTap: onPressed,
            color: background,
            lipColor: AppTokens.lavender,
            lip: 4,
            child: SizedBox.square(
              dimension: size - 4,
              child: Icon(icon, color: enabled ? foreground : AppTokens.navyMuted, size: size * 0.46),
            ),
          ),
        ),
      ),
    );
  }
}

class BackChildButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const BackChildButton({super.key, this.onPressed});
  @override
  Widget build(BuildContext context) => ChildIconButton(
        icon: AppIcons.back,
        label: 'Back',
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      );
}

class HomeChildButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const HomeChildButton({super.key, this.onPressed});
  @override
  Widget build(BuildContext context) => ChildIconButton(
        icon: AppIcons.home,
        label: 'Home',
        onPressed: onPressed ?? () => Navigator.of(context).popUntil((r) => r.isFirst),
      );
}

class AudioReplayButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final double size;
  const AudioReplayButton({super.key, required this.onPressed, this.label = 'Listen again', this.size = 64});
  @override
  Widget build(BuildContext context) => ChildIconButton(
        icon: AppIcons.listen,
        label: label,
        onPressed: onPressed,
        size: size,
      );
}

class PauseChildButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const PauseChildButton({super.key, required this.onPressed});
  @override
  Widget build(BuildContext context) => ChildIconButton(icon: AppIcons.pause, label: 'Pause', onPressed: onPressed);
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;

  /// White button with violet text, for use on coloured cards.
  final bool inverted;
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon, this.expand = false, this.inverted = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = inverted ? AppTokens.purple : Colors.white;
    final text = Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 21, color: fg, fontWeight: FontWeight.w800);
    return _ButtonFrame(
      label: label,
      enabled: enabled,
      expand: expand,
      minWidth: 160,
      child: Chunky(
        onTap: onPressed,
        color: inverted ? AppTokens.surface : AppTokens.purple,
        gradient: enabled && !inverted ? AppTokens.primary : null,
        lipColor: inverted ? const Color(0xFFD9CCFF) : AppTokens.purpleDeep,
        glow: !inverted,
        radius: 22,
        child: _ButtonBody(label: label, icon: icon, iconSize: 26, style: text, color: fg),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;
  const SecondaryButton({super.key, required this.label, required this.onPressed, this.icon, this.expand = false});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTokens.navy, fontWeight: FontWeight.w700);
    return _ButtonFrame(
      label: label,
      enabled: onPressed != null,
      expand: expand,
      minWidth: 140,
      child: Chunky(
        onTap: onPressed,
        color: AppTokens.surface,
        lipColor: AppTokens.outline,
        radius: 22,
        glow: false,
        border: Border.all(color: AppTokens.outline, width: 2),
        child: _ButtonBody(label: label, icon: icon, iconSize: 24, style: text, color: AppTokens.purple),
      ),
    );
  }
}

/// Shared sizing and semantics for the chunky buttons.
class _ButtonFrame extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool expand;
  final double minWidth;
  final Widget child;
  const _ButtonFrame({required this.label, required this.enabled, required this.expand, required this.minWidth, required this.child});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: enabled,
        label: label,
        excludeSemantics: true,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: expand ? double.infinity : minWidth),
            child: child,
          ),
        ),
      );
}

class _ButtonBody extends StatelessWidget {
  final String label;
  final IconData? icon;
  final double iconSize;
  final TextStyle? style;
  final Color color;
  const _ButtonBody({required this.label, required this.icon, required this.iconSize, required this.style, required this.color});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTokens.childTarget - AppTokens.lip + 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
          child: Center(
            widthFactor: 1,
            child: DefaultTextStyle.merge(
              style: style,
              child: IconTheme.merge(
                data: IconThemeData(color: color, size: iconSize),
                child: _ButtonLabel(label: label, icon: icon, iconSize: iconSize),
              ),
            ),
          ),
        ),
      );
}

/// Icon + label that wraps instead of overflowing at large text sizes.
class _ButtonLabel extends StatelessWidget {
  final String label;
  final IconData? icon;
  final double iconSize;
  const _ButtonLabel({required this.label, required this.icon, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    final text = Text(label, textAlign: TextAlign.center);
    if (icon == null) return text;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: iconSize),
      const SizedBox(width: 8),
      Flexible(child: text),
    ]);
  }
}
