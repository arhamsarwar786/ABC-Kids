import 'package:flutter/foundation.dart';

/// Counts active play time (only while an activity runs in the foreground and
/// is not paused) and says when a gentle break reminder is due. There is no
/// hard limit: the learner can always continue.
class ActiveTimeTracker extends ChangeNotifier {
  final DateTime Function() _now;
  Duration _accumulated = Duration.zero;
  DateTime? _runningSince;
  Duration _lastAcknowledged = Duration.zero;
  Duration? threshold;

  ActiveTimeTracker({this.threshold, DateTime Function()? now}) : _now = now ?? DateTime.now;

  bool get running => _runningSince != null;

  Duration get elapsed {
    final since = _runningSince;
    return since == null ? _accumulated : _accumulated + _now().difference(since);
  }

  void start() {
    _runningSince ??= _now();
  }

  void pause() {
    final since = _runningSince;
    if (since == null) return;
    _accumulated += _now().difference(since);
    _runningSince = null;
  }

  void setMinutes(int minutes) {
    threshold = minutes <= 0 ? null : Duration(minutes: minutes);
  }

  bool get reminderDue {
    final t = threshold;
    return t != null && elapsed - _lastAcknowledged >= t;
  }

  /// Learner chose to continue: the next reminder comes one threshold later.
  void acknowledge() {
    _lastAcknowledged = elapsed;
    notifyListeners();
  }

  /// Learner finished: start a fresh session next time.
  void resetSession() {
    _accumulated = Duration.zero;
    _lastAcknowledged = Duration.zero;
    _runningSince = null;
    notifyListeners();
  }
}
