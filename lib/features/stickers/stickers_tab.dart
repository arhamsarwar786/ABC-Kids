import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/art/art_kit.dart';
import '../../core/design/art/word_art.dart';
import '../../core/design/components/feedback.dart';
import '../../core/design/components/scaffolds.dart';
import '../../core/design/tokens.dart';
import '../../data/content/stickers.dart';
import '../../state/progress_store.dart';
import 'sticker_art.dart';
import '../../core/design/components/motion.dart';
import '../../core/design/app_icons.dart';

/// Per-learner sticker book. No streaks, counters to beat or timers.
class StickersTab extends StatelessWidget {
  const StickersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressStore>();
    final stickers = progress.stickers;
    final legacy = progress.data.legacyStars;
    final t = Theme.of(context).textTheme;
    final emptySlots = stickers.length < 6 ? 6 - stickers.length : (stickers.length.isOdd ? 1 : 0);
    return ChildScaffold(
      title: 'My Stickers',
      scene: SceneTheme.sunset,
      trailing: [
        Semantics(
          label: '${stickers.length + legacy} stickers',
          excludeSemantics: true,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFE08A), width: 2),
              boxShadow: AppTokens.softShadow,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(AppIcons.star, color: Color(0xFFFFB800), size: 24),
              const SizedBox(width: 4),
              Text('${stickers.length + legacy}', style: t.titleLarge?.copyWith(height: 1), textScaler: TextScaler.noScaling),
            ]),
          ),
        ),
      ],
      body: CustomScrollView(slivers: [
        if (stickers.isEmpty && legacy == 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SoftCard(
                child: Row(children: [
                  const Art(StarArt(color: Color(0xFFE7E3D8)), size: 56),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Your stickers will appear here when you finish a lesson or a game.', style: t.bodyLarge)),
                ]),
              ),
            ),
          ),
        if (legacy > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SoftCard(
                color: AppTokens.yellow.withValues(alpha: 0.5),
                child: Row(children: [
                  const Art(StarArt(), size: 56),
                  const SizedBox(width: 12),
                  Expanded(child: Text('$legacy ${legacy == 1 ? 'star' : 'stars'} from before', style: t.titleLarge)),
                ]),
              ),
            ),
          ),
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.8),
          delegate: SliverChildListDelegate([
            for (final (i, s) in stickers.indexed)
              Entrance(
                index: i,
                child: Transform.rotate(
                  angle: const [-0.06, 0.04, -0.02, 0.06, -0.04, 0.02][i % 6],
                  child: StickerBadge(art: StickerArtView(s.stickerId), label: StickerCatalog.byId(s.stickerId).name, size: 96),
                ),
              ),
            for (var i = 0; i < emptySlots; i++) const Align(alignment: Alignment.topCenter, child: StickerBadge.empty(size: 96)),
          ]),
        ),
      ]),
    );
  }
}
