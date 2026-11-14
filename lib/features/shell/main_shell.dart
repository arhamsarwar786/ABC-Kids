import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/audio/audio_coordinator.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/components/motion.dart';
import '../../core/design/tokens.dart';
import '../alphabet/alphabet_screen.dart';
import '../games/games_catalogue.dart';
import '../home/home_tab.dart';
import '../shared/widgets/ad_slot.dart';
import '../stickers/stickers_tab.dart';

enum ShellTab { home, abc, games, stickers }

/// Browse shell with Home / ABC / Games / Stickers tabs. Activities are
/// pushed as full-screen routes on top, so the tabs are hidden while playing.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static void selectTab(BuildContext context, ShellTab tab) => context.findAncestorStateOfType<_MainShellState>()?._select(tab.index);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  AdRouteTracker? _tracker;
  Route<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lets the app-wide bottom strip step aside while this shell (which docks
    // its own banner above the tab bar) is the screen on top.
    _tracker = Provider.of<AdRouteTracker?>(context, listen: false);
    _route = ModalRoute.of(context);
    if (_route != null) _tracker?.registerShell(_route);
  }

  @override
  void dispose() {
    if (_route != null) _tracker?.unregisterShell(_route!);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AudioCoordinator>().enableMusic();
    });
  }

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.ivory,
      body: IndexedStack(
        index: _index,
        children: const [HomeTab(), AlphabetScreen(asTab: true), GamesCatalogue(), StickersTab()],
      ),
      // Banner docked directly above the tab bar, which stays at the very bottom.
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        const BannerSlot(style: BannerStyle.strip),
        KidTabBar(index: _index, onSelect: _select),
      ]),
    );
  }
}

class _TabSpec {
  final String label;
  final IconData icon;
  final Color color;
  const _TabSpec(this.label, this.icon, this.color);
}

/// Colourful, chunky tab bar: each tab has its own colour; the selected
/// tab rises in a filled bubble, the others sit in a soft tint.
class KidTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  const KidTabBar({super.key, required this.index, required this.onSelect});

  static const tabs = [
    _TabSpec('Home', AppIcons.tabHome, Color(0xFF7B5CF5)),
    _TabSpec('ABC', AppIcons.tabAbc, Color(0xFFFF7A66)),
    _TabSpec('Games', AppIcons.tabGames, Color(0xFF2FBF8A)),
    _TabSpec('Stickers', AppIcons.tabStickers, Color(0xFFFFB020)),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppTokens.outline, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x223B2A8C), blurRadius: 28, offset: Offset(0, 10)),
            BoxShadow(color: Color(0xFFE6DEF7), offset: Offset(0, 5)),
          ],
        ),
        child: Row(children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: _TabItem(
                spec: tabs[i],
                selected: i == index,
                position: '${i + 1} of ${tabs.length}',
                onTap: () => onSelect(i),
              ),
            ),
        ]),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final _TabSpec spec;
  final bool selected;
  final String position;
  final VoidCallback onTap;
  const _TabItem({required this.spec, required this.selected, required this.position, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = motion(context, const Duration(milliseconds: 240));
    final c = spec.color;
    final text = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: selected ? AppTokens.shade(c, 0.12) : AppTokens.navyMuted,
          height: 1.1,
        );
    return Semantics(
      button: true,
      selected: selected,
      label: '${spec.label}, tab $position',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: d,
            // No overshoot here: shadows can't animate past their end values.
            curve: Curves.easeOut,
            width: 54,
            height: 48,
            transform: Matrix4.translationValues(0, selected ? -4 : 0, 0),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: selected
                  ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTokens.tint(c, 0.25), c])
                  : null,
              color: selected ? null : AppTokens.tint(c, 0.86),
              boxShadow: selected
                  ? [
                      BoxShadow(color: AppTokens.shade(c, 0.15), offset: const Offset(0, 4)),
                      BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 8)),
                    ]
                  : null,
            ),
            child: AnimatedScale(
              duration: d,
              curve: Curves.easeOutBack,
              scale: selected ? 1.08 : 1,
              child: Icon(spec.icon, size: 28, color: selected ? Colors.white : c),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, child: Text(spec.label, style: text, maxLines: 1)),
        ]),
      ),
    );
  }
}
