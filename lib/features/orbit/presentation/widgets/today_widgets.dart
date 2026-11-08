import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../help/presentation/feature_walkthrough.dart';
import '../../../help/presentation/orbit_help.dart';
import '../../../../shared/widgets/icon_bubble.dart';
import '../../../../shared/widgets/time_chip.dart';
import '../../domain/planner_models.dart';
import '../../domain/schedule_block.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.onAddTaskTap,
    required this.onRemindersTap,
    super.key,
  });

  final VoidCallback onAddTaskTap;
  final VoidCallback onRemindersTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orbit.',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.4,
                    ),
                  ),
                ],
              ),
            ),
            TourTarget(
              id: 'today.add',
              child: IconButton.filled(
                onPressed: onAddTaskTap,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.text,
                ),
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Add To Today Timeline',
              ),
            ),
            const SizedBox(width: 8),
            TourTarget(
              id: 'today.reminders',
              child: IconButton.filled(
                onPressed: onRemindersTap,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.notifications_rounded),
                tooltip: 'Reminders',
              ),
            ),
            const OrbitAboutButton(),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Your day, sorted into doable moments.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class DateRail extends StatelessWidget {
  const DateRail({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday % 7));
    final days = [
      for (var index = 0; index < 7; index++)
        weekStart.add(Duration(days: index)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatHeaderDate(today),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 82 * MediaQuery.textScalerOf(context).scale(1),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final day = days[index];
              final selected =
                  day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;
              return Container(
                width:
                    ((MediaQuery.sizeOf(context).width.clamp(0, 880) - 80) / 7)
                        .clamp(42, 82),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.text : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? AppColors.text : AppColors.border,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _weekdayLabel(day),
                      maxLines: 1,
                      softWrap: false,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected ? Colors.white : AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day.day.toString(),
                      maxLines: 1,
                      softWrap: false,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: selected ? Colors.white : AppColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static String _formatHeaderDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String _weekdayLabel(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }
}

class NextFocusCard extends StatelessWidget {
  const NextFocusCard({
    required this.task,
    required this.focusStarted,
    required this.snoozeCount,
    required this.onStart,
    required this.onSnooze,
    required this.onViewDetails,
    super.key,
  });

  final PlannerTask? task;
  final bool focusStarted;
  final int snoozeCount;
  final VoidCallback onStart;
  final VoidCallback onSnooze;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final currentTask = task;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.peach,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(
                icon: Icons.auto_awesome_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Do next',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      currentTask?.name ?? 'Plan Your First Task',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              TimeChip(label: currentTask?.status ?? 'Empty'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            currentTask == null
                ? 'Add a To Do or In Progress task in Plan. The next useful task will appear here.'
                : focusStarted
                ? 'Focus is running for this task. Keep only this task in front of you.'
                : 'Deadline: ${_formatTimelineDateTime(currentTask.dueDate)}. Start with one small visible step.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.softText,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TourTarget(
                  id: 'today.focus',
                  child: FilledButton.icon(
                    onPressed: currentTask == null ? null : onStart,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.text,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(focusStarted ? 'Focus running' : 'Start focus'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: currentTask == null ? null : onViewDetails,
                icon: const Icon(Icons.info_rounded),
                tooltip: 'View Task Details',
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: currentTask == null ? null : onSnooze,
                icon: const Icon(Icons.snooze_rounded),
                tooltip: snoozeCount == 0 ? 'Snooze' : 'Snoozed $snoozeCount',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.title,
    required this.action,
    required this.icon,
    required this.onActionTap,
    this.actionTourId,
    super.key,
  });

  final String? actionTourId;
  final String title;
  final String action;
  final IconData icon;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (actionTourId != null)
          TourTarget(
            id: actionTourId!,
            child: TextButton(onPressed: onActionTap, child: Text(action)),
          )
        else
          TextButton(onPressed: onActionTap, child: Text(action)),
      ],
    );
  }
}

class ScheduleList extends StatelessWidget {
  const ScheduleList({
    required this.blocks,
    required this.selectedIndex,
    required this.onBlockTap,
    super.key,
  });

  final List<ScheduleBlock> blocks;
  final int selectedIndex;
  final ValueChanged<int> onBlockTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(30),
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
        children: [
          for (var index = 0; index < blocks.length; index++)
            _ScheduleTile(
              block: blocks[index],
              isLast: index == blocks.length - 1,
              selected: index == selectedIndex,
              onTap: () => onBlockTap(index),
            ),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.block,
    required this.isLast,
    required this.selected,
    required this.onTap,
  });

  final ScheduleBlock block;
  final bool isLast;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                block.time,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: selected ? Colors.white : AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              IconBubble(icon: block.icon, color: block.color),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: AppColors.line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? AppColors.activeCard : AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selected ? AppColors.text : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            block.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        TimeChip(label: block.duration),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      block.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      block.details,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.softText,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TodayPlannerTimeline extends StatelessWidget {
  const TodayPlannerTimeline({
    required this.tasks,
    required this.onTaskTap,
    super.key,
  });

  final List<PlannerTask> tasks;
  final ValueChanged<PlannerTask> onTaskTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: tasks.isEmpty
          ? const _EmptyTodayPlannerTimeline()
          : Column(
              children: [
                for (var index = 0; index < tasks.length; index++)
                  _TodayPlannerTaskTile(
                    task: tasks[index],
                    isLast: index == tasks.length - 1,
                    onTap: () => onTaskTap(tasks[index]),
                  ),
              ],
            ),
    );
  }
}

class _TodayPlannerTaskTile extends StatelessWidget {
  const _TodayPlannerTaskTile({
    required this.task,
    required this.isLast,
    required this.onTap,
  });

  final PlannerTask task;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isInProgress = task.status == 'In Progress';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                task.status == 'To Do' ? 'To Do' : 'Doing',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              IconBubble(
                icon: isInProgress
                    ? Icons.pending_actions_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isInProgress ? AppColors.blue : AppColors.primary,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: AppColors.line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isInProgress
                      ? AppColors.activeCard
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isInProgress ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        TimeChip(label: task.priority),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Deadline: ${_formatTimelineDateTime(task.dueDate)} • ${task.category}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to view details, edit, or archive.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.softText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTodayPlannerTimeline extends StatelessWidget {
  const _EmptyTodayPlannerTimeline();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'No To Do or In Progress tasks yet. Add one from Plan to see it here.',
        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String _formatTimelineDateTime(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute $period';
}

class InboxCapture extends StatelessWidget {
  const InboxCapture({required this.onAdd, super.key});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const IconBubble(
            icon: Icons.edit_note_rounded,
            color: AppColors.violet,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Capture a task, appointment, bill, or random thought.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.softText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton.filled(
            onPressed: onAdd,
            style: IconButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(Icons.add_rounded, color: AppColors.text),
            tooltip: 'Add To Inbox',
          ),
        ],
      ),
    );
  }
}
