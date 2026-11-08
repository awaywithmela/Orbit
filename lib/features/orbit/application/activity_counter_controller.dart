import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activity_counter_state.dart';

final activityCounterControllerProvider =
    NotifierProvider<ActivityCounterController, ActivityCounterState>(
      ActivityCounterController.new,
    );

class ActivityCounterController extends Notifier<ActivityCounterState> {
  Timer? _timer;
  Timer? _repTimer;

  @override
  ActivityCounterState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _repTimer?.cancel();
    });
    return const ActivityCounterState.initial();
  }

  void toggleTimer() {
    if (state.isRunning) {
      _timer?.cancel();
      _timer = null;
      state = state.copyWith(isRunning: false);
      return;
    }

    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void resetTimer() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(elapsedSeconds: 0, isRunning: false);
  }

  void addRep() {
    if (state.reps >= state.targetReps) {
      _stopRepCounter();
      return;
    }
    state = state.copyWith(
      reps: state.reps + 1,
      totalReps: state.totalReps + 1,
    );
    if (state.reps >= state.targetReps) {
      _stopRepCounter();
    }
  }

  void subtractRep() {
    if (state.reps == 0) {
      return;
    }
    state = state.copyWith(
      reps: state.reps - 1,
      totalReps: state.totalReps == 0 ? 0 : state.totalReps - 1,
    );
  }

  void finishSet() {
    _stopRepCounter();
    state = state.copyWith(setNumber: state.setNumber + 1, reps: 0);
  }

  void resetReps() {
    _stopRepCounter();
    state = state.copyWith(reps: 0, setNumber: 1, totalReps: 0);
  }

  void updateTargetReps(int target) {
    final nextTarget = target.clamp(1, 99);
    if (state.reps >= nextTarget) {
      _stopRepCounter();
    }
    state = state.copyWith(targetReps: nextTarget);
  }

  void updateRepPace(int seconds) {
    final nextPace = seconds.clamp(1, 8);
    state = state.copyWith(repPaceSeconds: nextPace);
    if (state.isCountingReps) {
      _repTimer?.cancel();
      _repTimer = Timer.periodic(Duration(seconds: nextPace), (_) {
        addRep();
      });
    }
  }

  void toggleRepCounter() {
    if (state.isCountingReps) {
      _stopRepCounter();
      return;
    }
    if (state.reps >= state.targetReps) {
      state = state.copyWith(reps: 0);
    }
    state = state.copyWith(isCountingReps: true);
    _repTimer = Timer.periodic(Duration(seconds: state.repPaceSeconds), (_) {
      addRep();
    });
  }

  void _stopRepCounter() {
    _repTimer?.cancel();
    _repTimer = null;
    if (state.isCountingReps) {
      state = state.copyWith(isCountingReps: false);
    }
  }
}
