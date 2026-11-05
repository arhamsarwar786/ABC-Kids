import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/design/app_icons.dart';

/// Grown-up check before parent settings, deletions or anything outside
/// child play. It asks a multiplication question written in words, with
/// four number answers, so it needs reading and arithmetic rather than just a
/// long press. It is a barrier for young children, not verifiable parental
/// consent.
class ParentGate {
  static const int maxWrong = 3;
  static const Duration lockout = Duration(seconds: 30);
  static DateTime? _lockedUntil;

  static const _words = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'];

  /// Builds a question: (prompt, correct answer, four distinct options).
  static (String, int, List<int>) question(Random r) {
    final a = 3 + r.nextInt(7), b = 3 + r.nextInt(7);
    final answer = a * b;
    final options = <int>{answer};
    while (options.length < 4) {
      final delta = (r.nextInt(9) - 4) * (r.nextBool() ? 1 : a);
      final v = answer + delta;
      if (v > 0 && v != answer) options.add(v);
    }
    return ('What is ${_words[a]} times ${_words[b]}?', answer, options.toList()..shuffle(r));
  }

  static Future<bool> show(BuildContext context, {String reason = 'For grown-ups'}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _GateDialog(reason: reason),
    );
    return ok ?? false;
  }
}

class _GateDialog extends StatefulWidget {
  final String reason;
  const _GateDialog({required this.reason});
  @override
  State<_GateDialog> createState() => _GateDialogState();
}

class _GateDialogState extends State<_GateDialog> {
  final Random _r = Random();
  late (String, int, List<int>) _q = ParentGate.question(_r);
  int _wrong = 0;
  String? _message;

  bool get _locked {
    final until = ParentGate._lockedUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  void _answer(int v) {
    if (_locked) return;
    if (v == _q.$2) {
      Navigator.pop(context, true);
      return;
    }
    _wrong++;
    setState(() {
      if (_wrong >= ParentGate.maxWrong) {
        ParentGate._lockedUntil = DateTime.now().add(ParentGate.lockout);
        _message = 'Please wait a little and try again.';
        _wrong = 0;
      } else {
        _message = 'Not quite. Here is a new question.';
      }
      _q = ParentGate.question(_r);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AlertDialog(
      title: Row(children: [
        const Icon(AppIcons.lock, color: AppTokens.purple),
        const SizedBox(width: 8),
        Expanded(child: Text(widget.reason)),
      ]),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_locked ? 'Too many tries. Please wait 30 seconds.' : _q.$1, style: t.titleLarge),
          const SizedBox(height: 14),
          if (!_locked)
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final o in _q.$3)
                SizedBox(
                  width: 96,
                  height: 56,
                  child: OutlinedButton(onPressed: () => _answer(o), child: Text('$o', style: t.titleLarge)),
                ),
            ]),
          if (_message != null) ...[const SizedBox(height: 12), Text(_message!, style: t.bodyMedium)],
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel'))],
    );
  }
}
