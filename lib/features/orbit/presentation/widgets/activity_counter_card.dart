import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../help/presentation/feature_walkthrough.dart';
import '../../application/activity_counter_controller.dart';

class ActivityCounterCard extends ConsumerWidget {
  const ActivityCounterCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(activityCounterControllerProvider);
    final controller = ref.read(activityCounterControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout Counter',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Time your exercise and count reps by set.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final timerPanel = _CounterPanel(
                label: 'Timer',
                value: counter.formattedTime,
                icon: Icons.timer_rounded,
                actions: [
                  TourTarget(
                    id: 'fitness.timer',
                    child: FilledButton.icon(
                      onPressed: controller.toggleTimer,
                      icon: Icon(
                        counter.isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(counter.isRunning ? 'Pause' : 'Start'),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Reset Timer',
                    onPressed: controller.resetTimer,
                    icon: const Icon(Icons.restart_alt_rounded),
                  ),
                ],
              );
              final repPanel = _RepCounterPanel(
                setNumber: counter.setNumber,
                reps: counter.reps,
                targetReps: counter.targetReps,
                repPaceSeconds: counter.repPaceSeconds,
                totalReps: counter.totalReps,
                isCounting: counter.isCountingReps,
                onAddRep: controller.addRep,
                onSubtractRep: controller.subtractRep,
                onTargetChanged: controller.updateTargetReps,
                onPaceChanged: controller.updateRepPace,
                onToggleCounter: controller.toggleRepCounter,
                onFinishSet: controller.finishSet,
                onReset: controller.resetReps,
              );

              if (constraints.maxWidth < 430) {
                return Column(
                  children: [timerPanel, const SizedBox(height: 12), repPanel],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: timerPanel),
                  const SizedBox(width: 12),
                  Expanded(child: repPanel),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RepCounterPanel extends StatelessWidget {
  const _RepCounterPanel({
    required this.setNumber,
    required this.reps,
    required this.targetReps,
    required this.repPaceSeconds,
    required this.totalReps,
    required this.isCounting,
    required this.onAddRep,
    required this.onSubtractRep,
    required this.onTargetChanged,
    required this.onPaceChanged,
    required this.onToggleCounter,
    required this.onFinishSet,
    required this.onReset,
  });

  final int setNumber;
  final int reps;
  final int targetReps;
  final int repPaceSeconds;
  final int totalReps;
  final bool isCounting;
  final VoidCallback onAddRep;
  final VoidCallback onSubtractRep;
  final ValueChanged<int> onTargetChanged;
  final ValueChanged<int> onPaceChanged;
  final VoidCallback onToggleCounter;
  final VoidCallback onFinishSet;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final progress = targetReps <= 0
        ? 0.0
        : (reps / targetReps).clamp(0.0, 1.0);
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.55),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fitness_center_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Set $setNumber',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$totalReps Total',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Target Reps',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Lower Target',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onTargetChanged(targetReps - 1),
                  icon: const Icon(Icons.remove_rounded, size: 18),
                ),
                SizedBox(
                  width: 42,
                  child: Center(
                    child: Text(
                      targetReps.toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton.filled(
                  tooltip: 'Raise Target',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onTargetChanged(targetReps + 1),
                  icon: const Icon(Icons.add_rounded, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Rep Pace',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Faster Count',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onPaceChanged(repPaceSeconds - 1),
                  icon: const Icon(Icons.remove_rounded, size: 18),
                ),
                SizedBox(
                  width: 72,
                  child: Center(
                    child: Text(
                      '${repPaceSeconds}s / rep',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton.filled(
                  tooltip: 'Slower Count',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onPaceChanged(repPaceSeconds + 1),
                  icon: const Icon(Icons.add_rounded, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onAddRep,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(112),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$reps / $targetReps',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(reps >= targetReps ? 'Set Complete' : 'Tap For Each Rep'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: AppColors.chip,
            color: AppColors.blue,
          ),
          const SizedBox(height: 12),
          TourTarget(
            id: 'fitness.reps',
            child: FilledButton.icon(
              onPressed: onToggleCounter,
              icon: Icon(
                isCounting ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(isCounting ? 'Pause Count' : 'Start Count'),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Subtract Rep',
                onPressed: onSubtractRep,
                icon: const Icon(Icons.remove_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TourTarget(
                  id: 'fitness.set',
                  child: FilledButton.tonalIcon(
                    onPressed: onFinishSet,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Finish Set'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Reset All Reps',
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterPanel extends StatelessWidget {
  const _CounterPanel({
    required this.label,
    required this.value,
    required this.icon,
    required this.actions,
  });

  final String label;
  final String value;
  final IconData icon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.55),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }
}
