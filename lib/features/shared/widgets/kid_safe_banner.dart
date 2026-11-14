import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/tokens.dart';
import 'ad_slot.dart';

/// Wraps the whole app so every screen has a banner docked at the bottom, in
/// its own strip *outside* the screen's content (never drawn over buttons or
/// game areas). Screens with a tab bar dock their own banner directly above
/// it instead, so this strip steps aside while the tab shell is on top.
class AdFrame extends StatefulWidget {
  final Widget child;
  const AdFrame({super.key, required this.child});

  @override
  State<AdFrame> createState() => _AdFrameState();
}

class _AdFrameState extends State<AdFrame> {
  final _stripLoaded = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _stripLoaded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final shellOnTop = context.watch<AdRouteTracker?>()?.shellOnTop ?? false;
    // The keyboard covers the strip, so drop it while typing.
    final hidden = shellOnTop || mq.viewInsets.bottom > 0;
    return ColoredBox(
      color: AppTokens.ivory,
      child: Column(children: [
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: _stripLoaded,
            // The strip owns the bottom safe area while it is showing.
            // Always the same widget shape, so the navigator below keeps its state.
            builder: (context, loaded, child) {
              final own = loaded && !hidden;
              return MediaQuery(
                data: own
                    ? mq.copyWith(
                        padding: mq.padding.copyWith(bottom: 0),
                        viewPadding: mq.viewPadding.copyWith(bottom: 0),
                      )
                    : mq,
                child: child!,
              );
            },
            child: widget.child,
          ),
        ),
        Offstage(
          offstage: hidden,
          child: BannerSlot(
            style: BannerStyle.strip,
            active: !shellOnTop,
            bottomInset: mq.viewPadding.bottom,
            onLoadedChanged: (v) => WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _stripLoaded.value = v;
            }),
          ),
        ),
      ]),
    );
  }
}
