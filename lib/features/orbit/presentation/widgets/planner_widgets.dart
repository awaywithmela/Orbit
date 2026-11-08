import 'package:flutter/material.dart';

import '../../../../core/formatting/currency_format.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../help/presentation/feature_walkthrough.dart';
import '../../domain/planner_models.dart';

class PlannerSection extends StatelessWidget {
  const PlannerSection({
    required this.planner,
    required this.onAddTask,
    required this.onEditTask,
    required this.onTaskTap,
    required this.onStatusChanged,
    required this.onAddGoal,
    required this.onToggleGoal,
    required this.onEditGoal,
    required this.onAddNote,
    required this.onDeleteNote,
    super.key,
  });

  final PlannerState planner;
  final ValueChanged<String> onAddTask;
  final ValueChanged<PlannerTask> onEditTask;
  final ValueChanged<PlannerTask> onTaskTap;
  final void Function(PlannerTask task, String status) onStatusChanged;
  final VoidCallback onAddGoal;
  final ValueChanged<int> onToggleGoal;
  final ValueChanged<int> onEditGoal;
  final ValueChanged<String> onAddNote;
  final ValueChanged<PlannerNote> onDeleteNote;

  @override
  Widget build(BuildContext context) {
    final statuses = ['To Do', 'In Progress', 'Done'];
    final activeTasks = planner.tasks
        .where((task) => task.status != 'Archived')
        .toList();
    final dailyTasks = activeTasks.where(_isDailyTask).toList();
    final upcomingTasks = activeTasks
        .where((task) => !_isDailyTask(task))
        .toList();
    final completedGoals = planner.goals.where((goal) => goal.complete).length;
    final goalProgress = planner.goals.isEmpty
        ? 0.0
        : completedGoals / planner.goals.length;

    return Column(
      children: [
        _PlannerPanel(
          title: 'Planner & Goals',
          trailing: TourTarget(
            id: 'plan.task',
            child: TextButton.icon(
              onPressed: () => onAddTask('To Do'),
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Task'),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Task Planner',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'This board updates every day from due dates. Overdue and today tasks stay here until Done.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Today: ${_formatPlannerDate(DateTime.now())}',
                style: const TextStyle(
                  color: AppColors.softText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final status in statuses)
                _TaskStatusColumn(
                  status: status,
                  tasks: dailyTasks
                      .where((task) => task.status == status)
                      .toList(),
                  onAddTask: () => onAddTask(status),
                  onEditTask: onEditTask,
                  onTaskTap: onTaskTap,
                  onStatusChanged: onStatusChanged,
                ),
              if (upcomingTasks.isNotEmpty) ...[
                const SizedBox(height: 6),
                _UpcomingTasksPanel(
                  tasks: upcomingTasks,
                  onEditTask: onEditTask,
                  onTaskTap: onTaskTap,
                  onStatusChanged: onStatusChanged,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Monthly Goals ($completedGoals/${planner.goals.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TourTarget(
                    id: 'plan.goal',
                    child: TextButton.icon(
                      key: const ValueKey('addMonthlyGoalButton'),
                      onPressed: onAddGoal,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Goal'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: goalProgress,
                minHeight: 10,
                borderRadius: BorderRadius.circular(999),
                color: AppColors.primary,
                backgroundColor: AppColors.chip,
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < planner.goals.length; index++)
                _MonthlyGoalCard(
                  index: index,
                  goal: planner.goals[index],
                  onToggle: () => onToggleGoal(index),
                  onEdit: () => onEditGoal(index),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _NotesPanel(
          notes: planner.notes,
          onAdd: onAddNote,
          onDelete: onDeleteNote,
        ),
      ],
    );
  }
}

class _NotesPanel extends StatefulWidget {
  const _NotesPanel({
    required this.notes,
    required this.onAdd,
    required this.onDelete,
  });

  final List<PlannerNote> notes;
  final ValueChanged<String> onAdd;
  final ValueChanged<PlannerNote> onDelete;

  @override
  State<_NotesPanel> createState() => _NotesPanelState();
}

class _NotesPanelState extends State<_NotesPanel> {
  final _controller = TextEditingController();
  final _notesScrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _NotesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notes.length > oldWidget.notes.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_notesScrollController.hasClients) {
          _notesScrollController.animateTo(
            _notesScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _notesScrollController.dispose();
    super.dispose();
  }

  void _addNote() {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    widget.onAdd(body);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _PlannerPanel(
      title: 'Notes',
      trailing: Text(
        '${widget.notes.length} ${widget.notes.length == 1 ? 'note' : 'notes'}',
        style: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Capture thoughts for this month. Notes are listed oldest to newest.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.chip,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Icon(
                          Icons.sticky_note_2_rounded,
                          size: 20,
                          color: AppColors.blue,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New note',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Add it to your monthly note stack.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TourTarget(
                  id: 'plan.notes',
                  child: TextField(
                    key: const ValueKey('quickNotesField'),
                    controller: _controller,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText:
                          'Capture an idea, reminder, or something to revisit…',
                      alignLabelWithHint: true,
                      filled: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Each note saves as its own card.',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      key: const ValueKey('saveQuickNotesButton'),
                      onPressed: _controller.text.trim().isEmpty
                          ? null
                          : _addNote,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Add note'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.notes.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Center(
                child: Text(
                  'No notes yet.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (widget.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: Scrollbar(
                  controller: _notesScrollController,
                  thumbVisibility: widget.notes.length > 3,
                  child: ListView.separated(
                    key: const ValueKey('notesCardList'),
                    controller: _notesScrollController,
                    primary: false,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(right: 8),
                    itemCount: widget.notes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _NoteCard(
                      note: widget.notes[index],
                      number: index + 1,
                      onDelete: () => widget.onDelete(widget.notes[index]),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.number,
    required this.onDelete,
  });

  final PlannerNote note;
  final int number;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.chip,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: AppColors.softText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                note.body,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Delete note $number',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _TaskStatusColumn extends StatelessWidget {
  const _TaskStatusColumn({
    required this.status,
    required this.tasks,
    required this.onAddTask,
    required this.onEditTask,
    required this.onTaskTap,
    required this.onStatusChanged,
  });

  final String status;
  final List<PlannerTask> tasks;
  final VoidCallback onAddTask;
  final ValueChanged<PlannerTask> onEditTask;
  final ValueChanged<PlannerTask> onTaskTap;
  final void Function(PlannerTask task, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  status,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onAddTask,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('Add $status'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (tasks.isEmpty)
            const Text(
              'No tasks here yet.',
              style: TextStyle(color: AppColors.muted),
            ),
          if (tasks.isNotEmpty)
            _ScrollablePlannerTaskList(
              tasks: tasks,
              onEditTask: onEditTask,
              onTaskTap: onTaskTap,
              onStatusChanged: onStatusChanged,
            ),
        ],
      ),
    );
  }
}

class _UpcomingTasksPanel extends StatelessWidget {
  const _UpcomingTasksPanel({
    required this.tasks,
    required this.onEditTask,
    required this.onTaskTap,
    required this.onStatusChanged,
  });

  final List<PlannerTask> tasks;
  final ValueChanged<PlannerTask> onEditTask;
  final ValueChanged<PlannerTask> onTaskTap;
  final void Function(PlannerTask task, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Tasks',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'These appear on the daily board when their due date arrives.',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          _ScrollablePlannerTaskList(
            tasks: tasks,
            onEditTask: onEditTask,
            onTaskTap: onTaskTap,
            onStatusChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }
}

class _ScrollablePlannerTaskList extends StatelessWidget {
  const _ScrollablePlannerTaskList({
    required this.tasks,
    required this.onEditTask,
    required this.onTaskTap,
    required this.onStatusChanged,
  });

  final List<PlannerTask> tasks;
  final ValueChanged<PlannerTask> onEditTask;
  final ValueChanged<PlannerTask> onTaskTap;
  final void Function(PlannerTask task, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final list = Column(
      children: [
        for (final task in tasks)
          _PlannerTaskTile(
            task: task,
            onTap: () => onTaskTap(task),
            onEdit: () => onEditTask(task),
            onStatusChanged: (status) => onStatusChanged(task, status),
          ),
      ],
    );

    if (tasks.length <= 3) {
      return list;
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: SingleChildScrollView(padding: EdgeInsets.zero, child: list),
    );
  }
}

class _MonthlyGoalCard extends StatelessWidget {
  const _MonthlyGoalCard({
    required this.index,
    required this.goal,
    required this.onToggle,
    required this.onEdit,
  });

  final int index;
  final MonthlyGoal goal;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Checkbox(value: goal.complete, onChanged: (_) => onToggle()),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.text,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (goal.targetAmount != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Target: ${formatCurrency(context, goal.targetAmount!)}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton.filledTonal(
            key: ValueKey('editMonthlyGoal-$index'),
            tooltip: 'Edit Monthly Goal',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _PlannerTaskTile extends StatelessWidget {
  const _PlannerTaskTile({
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onStatusChanged,
  });

  final PlannerTask task;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final dueLabel = _formatDueDate(task.dueDate);
    final dateColor = task.isOverdue ? AppColors.blue : AppColors.muted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.chip,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.name,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit Task',
                    visualDensity: VisualDensity.compact,
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                  ),
                ],
              ),
              Text(
                '$dueLabel at ${_formatDueTime(task.dueDate)} • ${task.priority} • ${task.category}',
                style: TextStyle(color: dateColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final status in const ['To Do', 'In Progress', 'Done'])
                    ChoiceChip(
                      selected: task.status == status,
                      label: Text(status),
                      onSelected: (_) => onStatusChanged(status),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDueDate(DateTime date) {
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
  final today = DateTime.now();
  final dateOnly = DateTime(date.year, date.month, date.day);
  final todayOnly = DateTime(today.year, today.month, today.day);
  if (dateOnly == todayOnly) {
    return 'Due Today';
  }
  if (dateOnly == todayOnly.add(const Duration(days: 1))) {
    return 'Due Tomorrow';
  }
  return 'Due ${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _formatDueTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

bool _isDailyTask(PlannerTask task) {
  if (task.status == 'Archived') {
    return false;
  }
  return task.isDueToday || task.isOverdue || task.status == 'In Progress';
}

String _formatPlannerDate(DateTime date) {
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

class _PlannerPanel extends StatelessWidget {
  const _PlannerPanel({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
