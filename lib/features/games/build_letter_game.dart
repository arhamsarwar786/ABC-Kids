import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/art/stroke_painter.dart';
import '../../core/design/components/buttons.dart';
import '../../core/design/tokens.dart';
import '../../data/content/audio_manifest.dart';
import '../../data/content/content_catalog.dart';
import '../../data/models/content.dart';
import '../../engine/activity_engine.dart';
import '../../state/progress_store.dart';
import '../../core/design/components/scaffolds.dart';
import 'game_framework.dart';
import '../../core/design/app_icons.dart';

/// Build a Letter: place pieces that exactly match the letter's outline.
/// Drag a piece near its place (forgiving snap), or tap a piece then tap the
/// outline. A filled place cannot take another piece. Finishes automatically.
class BuildLetterGame extends GameWidget {
  const BuildLetterGame({super.key, required super.spec, required super.onFinished});
  @override
  State<BuildLetterGame> createState() => _BuildState();
}

class _BuildState extends GameState<BuildLetterGame> {
  /// slot index → piece index placed there.
  final Map<int, int> _placed = {};
  int? _selectedPiece;
  int? _hintSlot;
  bool _helped = false;
  late List<int> _trayOrder;
  int _roundSeen = -1;

  static const _pieceColors = [Color(0xFFFF8A80), Color(0xFF6FB1F0), Color(0xFF6CC9A0), Color(0xFF9C7BEA)];

  @override
  String get title => 'Build a Letter';

  @override
  SceneTheme get scene => SceneTheme.sky;

  @override
  bool get hasReplay => false;

  @override
  List<EngineRound> buildRounds() {
    final letters = widget.spec.letters.where((l) => ContentCatalog.letter(l)?.strokes != null).toList();
    final use = letters.isEmpty ? ['m'] : letters.take(3).toList();
    return [for (final l in use) EngineRound(targetId: Targets.letter(l), payload: l)];
  }

  List<LetterStroke> get _strokes => ContentCatalog.letter(engine.round.payload as String)!.strokes!.strokes;

  void _syncRound() {
    if (_roundSeen == engine.roundIndex) return;
    _roundSeen = engine.roundIndex;
    _placed.clear();
    _selectedPiece = null;
    _hintSlot = null;
    _helped = false;
    _trayOrder = List.generate(_strokes.length, (i) => i)..shuffle(random);
  }

  @override
  SkillDomain domainFor(EngineRound round) => SkillDomain.construction;

  @override
  String instructionFor(EngineRound round) => 'Build ${round.payload}';

  @override
  Future<bool> playPrompt(EngineRound round, PromptReason reason) async {
    if (reason == PromptReason.first && engine.roundIndex == 0) {
      await sayInstruction('Put the pieces in the letter!');
    }
    return true;
  }

  /// Nearest free slot whose shape matches [piece], within [tolerance] of the
  /// point (all in unit-box coordinates).
  int? _slotFor(int piece, Offset point, double tolerance) {
    final group = _strokes[piece].shapeGroup;
    int? best;
    var bestD = double.infinity;
    for (var s = 0; s < _strokes.length; s++) {
      if (_placed.containsKey(s) || _strokes[s].shapeGroup != group) continue;
      final d = (PiecePainter.bounds(_strokes[s]).center - point).distance;
      if (d < bestD) {
        bestD = d;
        best = s;
      }
    }
    return bestD <= tolerance ? best : null;
  }

  bool _place(int piece, Offset unitPoint, {required double tolerance}) {
    if (_placed.containsValue(piece)) return false;
    final slot = _slotFor(piece, unitPoint, tolerance);
    if (slot == null) {
      audio.playEffect(Effect.softTry);
      return false;
    }
    setState(() {
      _placed[slot] = piece;
      _selectedPiece = null;
      _hintSlot = null;
    });
    audio.playEffect(Effect.pop);
    if (_placed.length == _strokes.length) engine.completeTask(helped: _helped);
    return true;
  }

  void _hint() {
    final piece = _selectedPiece ?? _trayOrder.firstWhere((p) => !_placed.containsValue(p), orElse: () => -1);
    if (piece < 0) return;
    final group = _strokes[piece].shapeGroup;
    for (var s = 0; s < _strokes.length; s++) {
      if (!_placed.containsKey(s) && _strokes[s].shapeGroup == group) {
        setState(() {
          _hintSlot = s;
          _selectedPiece = piece;
          _helped = true;
        });
        return;
      }
    }
  }

  @override
  Widget buildBoard(BuildContext context) {
    _syncRound();
    return LayoutBuilder(builder: (context, c) {
      final pieceBox = math.min(96.0, (c.maxWidth - 40) / math.max(3, _strokes.length));
      final box = math.min(c.maxWidth, c.maxHeight - pieceBox - 120).clamp(120.0, 420.0);
      final frame = LetterFrame(_strokes, Size(box, box));
      final done = {for (final e in _placed.entries) e.key};
      return SingleChildScrollView(
          child: Column(children: [
        DragTarget<int>(
          onAcceptWithDetails: (d) {
            final targetBox = _outlineKey.currentContext?.findRenderObject() as RenderBox?;
            if (targetBox == null) return;
            // d.offset is the feedback's top-left; the piece sits at its centre.
            final centre = targetBox.globalToLocal(d.offset) + Offset(box / 2, box / 2);
            _place(d.data, frame.toUnit(centre), tolerance: frame.unitsFor(box * 0.22));
          },
          builder: (context, _, _) => Semantics(
            label: 'letter ${engine.round.payload} outline, ${_placed.length} of ${_strokes.length} pieces placed',
            child: GestureDetector(
              onTapUp: (d) {
                final p = _selectedPiece;
                if (p == null) return;
                _place(p, frame.toUnit(d.localPosition), tolerance: frame.unitsFor(box * 0.3));
              },
              child: Container(
                key: _outlineKey,
                width: box,
                height: box,
                decoration: BoxDecoration(color: const Color(0xFFFFF4E0), borderRadius: BorderRadius.circular(AppTokens.radius)),
                child: CustomPaint(
                  painter: _BuildPainter(
                    strokes: _strokes,
                    placed: _placed,
                    colors: _pieceColors,
                    hintSlot: _hintSlot,
                    done: done,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
          for (final p in _trayOrder)
            if (!_placed.containsValue(p)) _trayPiece(p, pieceBox, box, frame),
        ]),
        const SizedBox(height: 12),
        SecondaryButton(label: 'Show me where', icon: AppIcons.hint, onPressed: _hint),
      ]));
    });
  }

  final GlobalKey _outlineKey = GlobalKey();

  /// Fits a piece inside its tray tile.
  double _trayScale(int p, double size) {
    final b = PiecePainter.bounds(_strokes[p]);
    return size * 0.62 / math.max(b.width, b.height).clamp(0.08, 1.0);
  }

  Widget _trayPiece(int p, double size, double outlineBox, LetterFrame frame) {
    final color = _pieceColors[p % _pieceColors.length];
    final selected = _selectedPiece == p;
    final visual = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: selected ? AppTokens.purple : AppTokens.outline, width: selected ? 4 : 2),
      ),
      child: CustomPaint(painter: PiecePainter(_strokes[p], color, scale: _trayScale(p, size), strokeWidth: size * 0.12)),
    );
    final dragFeedback = SizedBox(
      width: outlineBox,
      height: outlineBox,
      child: CustomPaint(
          painter: PiecePainter(_strokes[p], color.withValues(alpha: 0.85), scale: frame.scale, strokeWidth: frame.strokeWidth)),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: 'letter piece ${p + 1}',
      excludeSemantics: true,
      child: Draggable<int>(
        data: p,
        dragAnchorStrategy: (d, ctx, pos) => Offset(outlineBox / 2, outlineBox / 2),
        feedback: Material(type: MaterialType.transparency, child: dragFeedback),
        childWhenDragging: Opacity(opacity: 0.3, child: visual),
        onDragStarted: () => setState(() => _selectedPiece = p),
        child: GestureDetector(onTap: () => setState(() => _selectedPiece = selected ? null : p), child: visual),
      ),
    );
  }
}

class _BuildPainter extends CustomPainter {
  final List<LetterStroke> strokes;
  final Map<int, int> placed;
  final List<Color> colors;
  final int? hintSlot;
  final Set<int> done;
  _BuildPainter({required this.strokes, required this.placed, required this.colors, required this.hintSlot, required this.done});

  @override
  void paint(Canvas canvas, Size size) {
    LetterGuidePainter(strokes: strokes, guideColor: const Color(0xFFEADBC4)).paint(canvas, size);
    final f = LetterFrame(strokes, size);
    final w = f.strokeWidth;
    if (hintSlot != null) {
      paintStroke(
          canvas,
          strokes[hintSlot!],
          f.toLocal,
          Paint()
            ..color = AppTokens.purple.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = w * 1.5);
    }
    for (final e in placed.entries) {
      paintStroke(
          canvas,
          strokes[e.key],
          f.toLocal,
          Paint()
            ..color = colors[e.value % colors.length]
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = w);
    }
  }

  @override
  bool shouldRepaint(covariant _BuildPainter oldDelegate) => true;
}
