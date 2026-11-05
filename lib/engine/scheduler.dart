import 'dart:async';

import 'package:flutter/foundation.dart';

abstract class Cancelable {
  void cancel();
}

/// Delayed callbacks that can all be cancelled when an activity pauses or exits.
abstract class Scheduler {
  Cancelable after(Duration delay, VoidCallback callback);
}

class TimerScheduler implements Scheduler {
  const TimerScheduler();

  @override
  Cancelable after(Duration delay, VoidCallback callback) => _TimerHandle(Timer(delay, callback));
}

class _TimerHandle implements Cancelable {
  final Timer _t;
  _TimerHandle(this._t);
  @override
  void cancel() => _t.cancel();
}

/// Manually driven scheduler for tests.
class ManualScheduler implements Scheduler {
  final List<_ManualTask> _tasks = [];

  @override
  Cancelable after(Duration delay, VoidCallback callback) {
    final t = _ManualTask(callback);
    _tasks.add(t);
    return t;
  }

  int get pending => _tasks.where((t) => !t.cancelled).length;

  /// Runs every pending (non-cancelled) task, including tasks they schedule,
  /// up to [maxSteps].
  void runAll({int maxSteps = 100}) {
    for (var i = 0; i < maxSteps; i++) {
      final next = _tasks.where((t) => !t.cancelled).toList();
      if (next.isEmpty) return;
      _tasks.clear();
      for (final t in next) {
        if (!t.cancelled) t.callback();
      }
    }
  }

  void runNext() {
    final idx = _tasks.indexWhere((t) => !t.cancelled);
    if (idx < 0) return;
    final t = _tasks.removeAt(idx);
    t.callback();
  }
}

class _ManualTask implements Cancelable {
  final VoidCallback callback;
  bool cancelled = false;
  _ManualTask(this.callback);
  @override
  void cancel() => cancelled = true;
}
