class ActivityCounterState {
  const ActivityCounterState({
    required this.elapsedSeconds,
    required this.reps,
    required this.targetReps,
    required this.repPaceSeconds,
    required this.setNumber,
    required this.totalReps,
    required this.isCountingReps,
    required this.isRunning,
  });

  const ActivityCounterState.initial()
    : elapsedSeconds = 0,
      reps = 0,
      targetReps = 16,
      repPaceSeconds = 3,
      setNumber = 1,
      totalReps = 0,
      isCountingReps = false,
      isRunning = false;

  final int elapsedSeconds;
  final int reps;
  final int targetReps;
  final int repPaceSeconds;
  final int setNumber;
  final int totalReps;
  final bool isCountingReps;
  final bool isRunning;

  String get formattedTime {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  ActivityCounterState copyWith({
    int? elapsedSeconds,
    int? reps,
    int? targetReps,
    int? repPaceSeconds,
    int? setNumber,
    int? totalReps,
    bool? isCountingReps,
    bool? isRunning,
  }) {
    return ActivityCounterState(
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      reps: reps ?? this.reps,
      targetReps: targetReps ?? this.targetReps,
      repPaceSeconds: repPaceSeconds ?? this.repPaceSeconds,
      setNumber: setNumber ?? this.setNumber,
      totalReps: totalReps ?? this.totalReps,
      isCountingReps: isCountingReps ?? this.isCountingReps,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}
