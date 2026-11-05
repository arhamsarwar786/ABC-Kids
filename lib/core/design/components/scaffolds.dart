import 'package:flutter/material.dart';

import '../tokens.dart';
import 'scene.dart';

export 'scene.dart' show SceneTheme;

/// Child-facing page: ivory background, large header controls, centred
/// content capped at a comfortable width for tablets.
class ChildScaffold extends StatelessWidget {
  final String? title;
  final List<Widget> leading;
  final List<Widget> trailing;
  final Widget body;
  final Widget? bottom;
  final bool scrollable;
  final double maxWidth;

  /// Illustrated backdrop; null uses the soft default gradient.
  final SceneTheme? scene;

  /// Below this height (small phones, large text) the body scrolls instead
  /// of overflowing.
  final double minBodyHeight;

  const ChildScaffold({
    super.key,
    this.title,
    this.leading = const [],
    this.trailing = const [],
    required this.body,
    this.bottom,
    this.scrollable = false,
    this.maxWidth = 760,
    this.minBodyHeight = 360,
    this.scene,
  });

  @override
  Widget build(BuildContext context) {
    final g = AppTokens.gutter(context);
    final header = (leading.isEmpty && trailing.isEmpty && title == null)
        ? const SizedBox.shrink()
        : Padding(
            padding: EdgeInsets.fromLTRB(g, 8, g, 4),
            child: Row(children: [
              ..._spaced(leading),
              if (title != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Semantics(
                      header: true,
                      child: Text(title!,
                          style: Theme.of(context).textTheme.headlineSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: leading.isEmpty ? TextAlign.start : TextAlign.center),
                    ),
                  ),
                )
              else
                const Spacer(),
              ..._spaced(trailing),
            ]),
          );
    Widget content = Padding(padding: EdgeInsets.fromLTRB(g, 8, g, 8), child: body);
    content = scrollable ? SingleChildScrollView(child: content) : MinHeightScroll(minHeight: minBodyHeight, child: content);
    final maxBottom = MediaQuery.sizeOf(context).height * 0.4;
    return Scaffold(
      backgroundColor: AppTokens.ivory,
      body: _Backdrop(
        scene: scene,
        child: SafeArea(
          child: Column(children: [
            header,
            Expanded(
              child: Center(
                child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: content),
              ),
            ),
            if (bottom != null)
              Padding(
                padding: EdgeInsets.fromLTRB(g, 4, g, 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxBottom),
                    child: SingleChildScrollView(child: bottom!),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  static List<Widget> _spaced(List<Widget> items) => [
        for (var i = 0; i < items.length; i++) ...[if (i > 0) const SizedBox(width: 10), items[i]],
      ];
}

class _Backdrop extends StatelessWidget {
  final SceneTheme? scene;
  final Widget child;
  const _Backdrop({required this.scene, required this.child});

  @override
  Widget build(BuildContext context) => scene == null
      ? DecoratedBox(decoration: const BoxDecoration(gradient: AppTokens.background), child: child)
      : SceneBackground(theme: scene!, child: child);
}

/// Parent-facing page: conventional app bar, denser text, scrollable list.
class ParentScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final Widget? bottom;
  const ParentScaffold({super.key, required this.title, required this.children, this.actions, this.bottom});

  @override
  Widget build(BuildContext context) {
    final g = AppTokens.gutter(context);
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      bottomNavigationBar: bottom,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(padding: EdgeInsets.fromLTRB(g, 8, g, 24), children: children),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Semantics(header: true, child: Text(text, style: Theme.of(context).textTheme.titleLarge)),
      );
}

class SoftCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  const SoftCard({super.key, required this.child, this.color = AppTokens.surface, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: color == AppTokens.surface ? AppTokens.outline : Colors.white, width: 2),
          boxShadow: AppTokens.softShadow,
        ),
        child: child,
      );
}

/// Gives [child] at least [minHeight], scrolling when the space is smaller.
class MinHeightScroll extends StatelessWidget {
  final double minHeight;
  final Widget child;
  const MinHeightScroll({super.key, required this.minHeight, required this.child});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => c.maxHeight >= minHeight ? child : SingleChildScrollView(child: SizedBox(height: minHeight, child: child)),
      );
}
