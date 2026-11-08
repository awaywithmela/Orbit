import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../help/presentation/orbit_help.dart';
import '../../help/presentation/feature_walkthrough.dart';
import '../../../core/formatting/currency_format.dart';
import '../../../core/ai/meal_plan_ai_service.dart';
import '../../../core/ads/orbit_banner_ad.dart';
import '../../../core/notifications/smart_notification_service.dart';
import '../../../shared/widgets/rounded_dropdown_form_field.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/user_profile.dart';
import '../application/orbit_controller.dart';
import '../domain/app_tab.dart';
import '../domain/finance_models.dart';
import '../domain/planner_models.dart';
import '../domain/schedule_block.dart';
import 'widgets/activity_counter_card.dart';
import 'widgets/meal_nutrition_details.dart';
import 'widgets/adhd_tool_card.dart';
import 'widgets/dialogs.dart';
import 'widgets/expense_widgets.dart';
import 'widgets/inbox_item_tile.dart';
import 'widgets/orbit_bottom_nav.dart';
import 'widgets/page_header.dart';
import 'widgets/planner_widgets.dart';
import 'widgets/today_widgets.dart';

class OrbitHomePage extends ConsumerWidget {
  const OrbitHomePage({super.key});

  static const _pagePadding = EdgeInsets.fromLTRB(22, 24, 22, 122);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orbitControllerProvider);
    final controller = ref.read(orbitControllerProvider.notifier);
    return FeatureWalkthroughHost(
      tab: state.selectedTab,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Stack(
                  children: [
                    switch (state.selectedTab) {
                      AppTab.today => _TodayPage(
                        onMessage: (message) => _showMessage(context, message),
                      ),
                      AppTab.plan => _PlanPage(
                        onMessage: (message) => _showMessage(context, message),
                      ),
                      AppTab.expenses => _ExpensePage(
                        onMessage: (message) => _showMessage(context, message),
                      ),
                      AppTab.fitness => _FitnessPage(
                        onMessage: (message) => _showMessage(context, message),
                      ),
                      AppTab.me => _MePage(
                        onMessage: (message) => _showMessage(context, message),
                      ),
                    },
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: OrbitBottomNav(
                        selectedTab: state.selectedTab,
                        onChanged: controller.selectTab,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 112),
        ),
      );
  }
}

class _TodayPage extends ConsumerWidget {
  const _TodayPage({required this.onMessage});

  final ValueChanged<String> onMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orbitControllerProvider);
    final controller = ref.read(orbitControllerProvider.notifier);
    final timelineTasks =
        state.planner.tasks
            .where(
              (task) => task.status == 'To Do' || task.status == 'In Progress',
            )
            .toList()
          ..sort((left, right) => left.dueDate.compareTo(right.dueDate));
    final nextTask = _nextActionTask(timelineTasks);

    return ListView(
      controller: WalkthroughScope.maybeOf(context)?.scrollController,
      padding: WalkthroughScope.paddingOf(context, OrbitHomePage._pagePadding),
      children: [
        HomeHeader(
          onAddTaskTap: () async {
            final task = await showAddTaskDialog(context);
            if (!context.mounted) {
              return;
            }
            if (task == null) {
              return;
            }
            controller.addTask(task);
            onMessage('Task added to today.');
          },
          onRemindersTap: () => _showReminderSheet(context),
        ),
        const SizedBox(height: 18),
        const FirstVisitGuide(tab: AppTab.today),
        const SizedBox(height: 12),
        const DateRail(),
        const SizedBox(height: 18),
        NextFocusCard(
          task: nextTask,
          focusStarted: state.focusStarted,
          snoozeCount: state.snoozeCount,
          onStart: () {
            controller.startFocus();
            onMessage('Focus started for ${nextTask?.name ?? 'your task'}.');
          },
          onSnooze: () {
            controller.snoozeFocus();
            onMessage('Snoozed this task for 10 minutes.');
          },
          onViewDetails: () {
            if (nextTask == null) {
              return;
            }
            _showTodayTaskDetailsDialog(
              context: context,
              task: nextTask,
              onEdit: () async {
                final updatedTask = await _showPlannerTaskDialog(
                  context,
                  initialTask: nextTask,
                );
                if (!context.mounted) {
                  return;
                }
                if (updatedTask != null) {
                  controller.updatePlannerTask(nextTask, updatedTask);
                  onMessage('Task Updated.');
                }
              },
              onArchive: () {
                controller.archivePlannerTask(nextTask);
                onMessage('Task Archived.');
              },
            );
          },
        ),
        const SizedBox(height: 12),
        AdhdToolCard(
          icon: Icons.self_improvement_rounded,
          title: 'Breathe And Choose One Task',
          subtitle: 'Take 30 seconds, then pick the next small step.',
          action: 'Start',
          onTap: () => _showResetSheet(context),
        ),
        const SizedBox(height: 18),
        SectionTitle(
          title: state.showTopThreeOnly
              ? 'Today Timeline (Top 3 Focus)'
              : 'Today Timeline',
          actionTourId: 'today.organize',
          action: 'Organize',
          icon: Icons.timeline_rounded,
          onActionTap: () => _showOrganizeSheet(context, onMessage),
        ),
        const SizedBox(height: 10),
        if (state.showTopThreeOnly)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.center_focus_strong_rounded,
                  color: AppColors.blue,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Focus Mode Active: Displaying Top 3 Priority Tasks',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    controller.toggleTopThreeOnly(false);
                    onMessage('Showing all schedule items.');
                  },
                  child: const Text('Show All'),
                ),
              ],
            ),
          ),
        TodayPlannerTimeline(
          tasks: state.showTopThreeOnly
              ? timelineTasks.take(3).toList()
              : timelineTasks,
          onTaskTap: (task) => _showTodayTaskDetailsDialog(
            context: context,
            task: task,
            onEdit: () async {
              final updatedTask = await _showPlannerTaskDialog(
                context,
                initialTask: task,
              );
              if (!context.mounted) {
                return;
              }
              if (updatedTask != null) {
                controller.updatePlannerTask(task, updatedTask);
                onMessage('Timeline Task Updated.');
              }
            },
            onArchive: () {
              controller.archivePlannerTask(task);
              onMessage('Task Archived.');
            },
          ),
        ),
        const SizedBox(height: 18),
        SectionTitle(
          title: 'Brain Dump',
          actionTourId: 'today.capture',
          action: 'Capture',
          icon: Icons.inbox_rounded,
          onActionTap: () => _captureBrainDump(
            context: context,
            controller: controller,
            onMessage: onMessage,
          ),
        ),
        const SizedBox(height: 10),
        InboxCapture(
          onAdd: () => _captureBrainDump(
            context: context,
            controller: controller,
            onMessage: onMessage,
          ),
        ),
        const SizedBox(height: 12),
        if (state.inboxItems.isEmpty)
          const _EmptyBrainDumpCard()
        else
          for (final item in state.inboxItems)
            InboxItemTile(
              title: item,
              onArchive: () {
                controller.archiveInboxItem(item);
                onMessage('Brain Dump Item Archived.');
              },
            ),
      ],
    );
  }
}

PlannerTask? _nextActionTask(List<PlannerTask> tasks) {
  final inProgressTasks =
      tasks.where((task) => task.status == 'In Progress').toList()
        ..sort((left, right) => left.dueDate.compareTo(right.dueDate));
  if (inProgressTasks.isNotEmpty) {
    return inProgressTasks.first;
  }

  final todoTasks = tasks.where((task) => task.status == 'To Do').toList()
    ..sort((left, right) => left.dueDate.compareTo(right.dueDate));
  return todoTasks.isEmpty ? null : todoTasks.first;
}

class _PlanPage extends ConsumerWidget {
  const _PlanPage({required this.onMessage});

  final ValueChanged<String> onMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orbitControllerProvider);
    final controller = ref.read(orbitControllerProvider.notifier);

    return ListView(
      controller: WalkthroughScope.maybeOf(context)?.scrollController,
      padding: WalkthroughScope.paddingOf(context, OrbitHomePage._pagePadding),
      children: [
        const PageHeader(
          title: 'Plan',
          subtitle: 'Build a day that has room to breathe.',
          icon: Icons.calendar_month_rounded,
        ),
        const FirstVisitGuide(tab: AppTab.plan),
        const SizedBox(height: 18),
        PlannerSection(
          planner: state.planner,
          onAddTask: (status) async {
            final task = await _showPlannerTaskDialog(
              context,
              initialStatus: status,
            );
            if (!context.mounted) {
              return;
            }
            if (task != null) {
              controller.addPlannerTask(task);
              onMessage('Planner task added.');
            }
          },
          onEditTask: (task) async {
            final updatedTask = await _showPlannerTaskDialog(
              context,
              initialTask: task,
            );
            if (!context.mounted) {
              return;
            }
            if (updatedTask != null) {
              controller.updatePlannerTask(task, updatedTask);
              onMessage('Planner Task Updated.');
            }
          },
          onTaskTap: (task) => _showTodayTaskDetailsDialog(
            context: context,
            task: task,
            onEdit: () async {
              final updatedTask = await _showPlannerTaskDialog(
                context,
                initialTask: task,
              );
              if (!context.mounted) {
                return;
              }
              if (updatedTask != null) {
                controller.updatePlannerTask(task, updatedTask);
                onMessage('Planner Task Updated.');
              }
            },
            onArchive: () {
              controller.archivePlannerTask(task);
              onMessage('Task Archived.');
            },
          ),
          onStatusChanged: (task, status) {
            controller.updatePlannerTaskStatus(task, status);
            onMessage('Task Moved To $status.');
          },
          onAddGoal: () async {
            final newGoal = await _showMonthlyGoalDialog(
              context,
              const MonthlyGoal(text: '', complete: false),
              isNew: true,
            );
            if (!context.mounted) {
              return;
            }
            if (newGoal != null) {
              controller.addMonthlyGoal(newGoal);
              onMessage('Monthly Goal Added.');
            }
          },
          onToggleGoal: controller.toggleGoal,
          onEditGoal: (index) async {
            final updatedGoal = await _showMonthlyGoalDialog(
              context,
              state.planner.goals[index],
            );
            if (!context.mounted) {
              return;
            }
            if (updatedGoal != null) {
              controller.updateMonthlyGoal(index, updatedGoal);
              onMessage('Monthly Goal Updated.');
            }
          },
          onAddNote: controller.addPlannerNote,
          onDeleteNote: controller.deletePlannerNote,
        ),
        const SizedBox(height: 18),
        AdhdToolCard(
          icon: Icons.hourglass_empty_rounded,
          tourId: 'plan.breaks',
          title: 'Add 10-Minute Breaks',
          subtitle:
              'Adds visible rest blocks after tasks 25 minutes or longer.',
          action: 'Add Breaks',
          onTap: () {
            final addedBreaks = controller.addTenMinuteBreaks();
            _showBreaksAddedDialog(context, addedBreaks, controller, onMessage);
          },
        ),
        const SizedBox(height: 12),
        AdhdToolCard(
          icon: Icons.low_priority_rounded,
          tourId: 'plan.top',
          title: 'Show Only Top 3',
          subtitle: 'See the next three must-do items from your schedule.',
          action: state.showTopThreeOnly ? 'Show All' : 'Show 3',
          onTap: () {
            controller.toggleTopThreeOnly();
            if (state.showTopThreeOnly) {
              onMessage('Showing all schedule items.');
            } else {
              onMessage('Focused view: Displaying Top 3 priority items.');
              _showTopThreeDialog(
                context,
                state.todayBlocks,
                state.selectedBlockIndex,
              );
            }
          },
        ),
        const SizedBox(height: 12),
        AdhdToolCard(
          icon: Icons.groups_rounded,
          tourId: 'plan.session',
          title: 'Focus Session Guide',
          subtitle: 'Use body doubling: work quietly with someone nearby.',
          action: 'Start Session',
          onTap: () => _showFocusGuideDialog(
            context,
            state.selectedBlock?.title ?? 'Active Focus Task',
            onMessage,
          ),
        ),
        const OrbitBannerAd(),
      ],
    );
  }
}

class _ExpensePage extends ConsumerWidget {
  const _ExpensePage({required this.onMessage});

  final ValueChanged<String> onMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orbitControllerProvider);
    final controller = ref.read(orbitControllerProvider.notifier);
    Future<void> addPurchase({String? accountName}) async {
      await controller.refreshLocal();
      if (!context.mounted) {
        return;
      }
      final month = ref.read(orbitControllerProvider).currentFinanceMonth;
      if (month.accounts.isEmpty) {
        onMessage('Add a bank or wallet before recording an expense.');
        return;
      }
      if (month.categoryBudgets.isEmpty) {
        onMessage('Add an expense category before recording an expense.');
        return;
      }
      final purchase = await showAddPurchaseDialog(
        context: context,
        categories: [for (final budget in month.categoryBudgets) budget.name],
        accounts: [for (final account in month.accounts) account.name],
        initialAccount: accountName,
      );
      if (!context.mounted) {
        return;
      }
      if (purchase == null) {
        return;
      }
      final saved = await controller.addPurchase(purchase);
      if (!context.mounted) {
        return;
      }
      onMessage(
        saved
            ? 'Expense saved. ${purchase.account} deducted ${formatCurrency(context, purchase.amount)}.'
            : 'Expense could not be saved. Check your wallet and category, then try again.',
      );
    }

    return ListView(
      key: const ValueKey('expensePageList'),
      controller: WalkthroughScope.maybeOf(context)?.scrollController,
      padding: WalkthroughScope.paddingOf(context, OrbitHomePage._pagePadding),
      children: [
        const PageHeader(
          title: 'Expenses',
          subtitle: 'Track Spending Without Shame Spirals.',
          icon: Icons.account_balance_wallet_rounded,
        ),
        const FirstVisitGuide(tab: AppTab.expenses),
        const SizedBox(height: 18),
        TourTarget(
          id: 'expense.add',
          child: FilledButton.icon(
            key: const ValueKey('addExpenseButton'),
            onPressed: addPurchase,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Expense'),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TourTarget(
                id: 'expense.wallet',
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final account = await showAddAccountDialog(context);
                    if (!context.mounted) {
                      return;
                    }
                    if (account != null) {
                      final saved = await controller.addAccount(account);
                      if (!context.mounted) {
                        return;
                      }
                      onMessage(
                        saved
                            ? 'Bank / wallet added.'
                            : 'Wallet already exists or could not be saved.',
                      );
                    }
                  },
                  icon: const Icon(Icons.account_balance_rounded),
                  label: const Text('New Wallet'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TourTarget(
                id: 'expense.category',
                child: OutlinedButton.icon(
                  key: const ValueKey('addExpenseCategoryButton'),
                  onPressed: () async {
                    final category = await showAddExpenseCategoryDialog(
                      context,
                    );
                    if (!context.mounted || category == null) {
                      return;
                    }
                    final saved = await controller.addExpenseCategory(
                      name: category.name,
                      color: category.color,
                      monthlyBudget: category.monthlyBudget,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    onMessage(
                      saved
                          ? '${category.name} is ready to use.'
                          : 'Category already exists or could not be saved.',
                    );
                  },
                  icon: const Icon(Icons.category_rounded),
                  label: const Text('New Category'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AccountBalanceStrip(
          month: state.currentFinanceMonth,
          onAddPurchaseForAccount: (account) =>
              addPurchase(accountName: account.name),
          onEditBalance: (account) async {
            final balance = await _showAmountDialog(
              context,
              title: '${account.name} Initial Balance',
              initialValue: account.initialBalance,
            );
            if (!context.mounted) {
              return;
            }
            if (balance != null) {
              controller.updateAccountBalance(account.name, balance);
            }
          },
        ),
        const SizedBox(height: 18),
        FinanceOverview(month: state.currentFinanceMonth),
        const SizedBox(height: 18),
        TourTarget(
          id: 'expense.month',
          child: MonthSelector(
            selectedMonth: state.selectedMonth,
            onChanged: controller.selectMonth,
          ),
        ),
        const SizedBox(height: 18),
        PurchaseLogTable(
          month: state.currentFinanceMonth,
          onAddPurchase: addPurchase,
          onArchivePurchase: controller.archivePurchase,
          onViewPurchase: (purchase, balanceAfter) =>
              _showPurchaseDetailDialog(context, purchase, balanceAfter),
          onViewReceipt: (purchase) => _showReceiptDialog(context, purchase),
        ),
        const SizedBox(height: 18),
        FinanceAnalytics(
          month: state.currentFinanceMonth,
          allMonths: state.financeMonths,
        ),
        const SizedBox(height: 18),
        CategoryBudgetTable(
          month: state.currentFinanceMonth,
          onEditBudget: (budget) async {
            final amount = await _showAmountDialog(
              context,
              title: '${budget.name} Monthly Budget',
              initialValue: budget.monthlyBudget,
            );
            if (!context.mounted) {
              return;
            }
            if (amount != null) {
              controller.updateCategoryBudget(budget.name, amount);
            }
          },
        ),
      ],
    );
  }
}

class _MePage extends ConsumerWidget {
  const _MePage({required this.onMessage});

  final ValueChanged<String> onMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider).profile;
    final state = ref.watch(orbitControllerProvider);
    final authController = ref.read(authControllerProvider.notifier);

    return ListView(
      controller: WalkthroughScope.maybeOf(context)?.scrollController,
      padding: WalkthroughScope.paddingOf(context, OrbitHomePage._pagePadding),
      children: [
        const PageHeader(
          title: 'Profile & Settings',
          subtitle: 'Manage your account, reminders, privacy, and saved data.',
          icon: Icons.manage_accounts_rounded,
        ),
        const FirstVisitGuide(tab: AppTab.me),
        const SizedBox(height: 18),
        const OrbitHelpLinks(),
        const SizedBox(height: 12),
        if (profile != null) ...[
          _ProfileSummaryCard(
            profile: profile,
            onEditProfile: () async {
              final updated = await _showEditProfileDialog(context, profile);
              if (!context.mounted || updated == null) return;
              await authController.updateProfile(updated);
              if (context.mounted) onMessage('Profile updated.');
            },
            onSignOut: () {
              authController.signOut();
              onMessage('Signed out.');
            },
          ),
          const SizedBox(height: 12),
          const _SettingsCard(),
          const SizedBox(height: 12),
          _ProfileArchiveCard(
            financeMonths: state.financeMonths,
            archivedInboxItems: state.archivedInboxItems,
            completedTasks: state.planner.tasks
                .where(
                  (task) => task.status == 'Done' || task.status == 'Archived',
                )
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _EmptyBrainDumpCard extends StatelessWidget {
  const _EmptyBrainDumpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'Saved thoughts will appear here.',
        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PriorityDialogTile extends StatelessWidget {
  const _PriorityDialogTile({
    required this.number,
    required this.block,
    required this.dateLabel,
    required this.reason,
  });

  final int number;
  final ScheduleBlock block;
  final String dateLabel;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.text,
            child: Text(
              number.toString(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${block.time} • ${block.title}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateLabel • ${block.duration}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  block.description,
                  style: const TextStyle(
                    color: AppColors.softText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  block.details,
                  style: const TextStyle(
                    color: AppColors.softText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reason,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusGuideStep extends StatelessWidget {
  const _FocusGuideStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: AppColors.chip,
            foregroundColor: AppColors.text,
            child: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.softText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FitnessPage extends ConsumerStatefulWidget {
  const _FitnessPage({required this.onMessage});

  final ValueChanged<String> onMessage;

  @override
  ConsumerState<_FitnessPage> createState() => _FitnessPageState();
}

class _FitnessPageState extends ConsumerState<_FitnessPage> {
  late var _selectedDietDay = DateTime.now().weekday;
  var _isGeneratingMealPlan = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orbitControllerProvider);
    final controller = ref.read(orbitControllerProvider.notifier);

    return ListView(
      controller: WalkthroughScope.maybeOf(context)?.scrollController,
      padding: WalkthroughScope.paddingOf(context, OrbitHomePage._pagePadding),
      children: [
        const PageHeader(
          title: 'Fitness',
          subtitle: 'Count gym reps, sets, stretches, and tiny workout wins.',
          icon: Icons.fitness_center_rounded,
        ),
        const FirstVisitGuide(tab: AppTab.fitness),
        const SizedBox(height: 18),
        const ActivityCounterCard(),
        const SizedBox(height: 12),
        _DietRoutineCard(
          selectedDay: _selectedDietDay,
          isGenerating: _isGeneratingMealPlan,
          meals: state.planner.dietPlans[_selectedDietDay] ?? const [],
          onDayChanged: (day) => setState(() => _selectedDietDay = day),
          onAddMeal: () async {
            final meal = await _showDietMealDialog(
              context,
              const DietMealPlan(
                title: '',
                time: '',
                focus: '',
                foods: '',
                notes: '',
              ),
              isNew: true,
            );
            if (!context.mounted) {
              return;
            }
            if (meal != null) {
              controller.addDietMealPlan(_selectedDietDay, meal);
              widget.onMessage('Meal Added.');
            }
          },
          onEditMeal: (index, meal) async {
            final updatedMeal = await _showDietMealDialog(context, meal);
            if (!context.mounted) {
              return;
            }
            if (updatedMeal != null) {
              controller.updateDietMealPlan(
                _selectedDietDay,
                index,
                updatedMeal,
              );
              widget.onMessage('Diet Plan Updated.');
            }
          },
          onAskAi: () async {
            final request = await _showAiMealPlanDialog(
              context,
              _weekdayNameFor(_selectedDietDay),
            );
            if (!context.mounted || request == null) return;
            setState(() => _isGeneratingMealPlan = true);
            try {
              final meals = await const MealPlanAiService().generate(request);
              if (!context.mounted) return;
              final accepted = await _showAiMealPlanPreview(context, meals);
              if (!context.mounted || accepted != true) return;
              final saved = await controller.addDietMealPlans(
                _selectedDietDay,
                meals,
              );
              if (context.mounted) {
                widget.onMessage(
                  saved
                      ? '${meals.length} healthy meal ideas added.'
                      : 'The meal plan could not be saved.',
                );
              }
            } on MealPlanAiException catch (error) {
              if (context.mounted) {
                widget.onMessage(error.message);
              }
            } catch (_) {
              if (context.mounted) {
                widget.onMessage(
                  'AI meal planning is temporarily unavailable.',
                );
              }
            } finally {
              if (mounted) setState(() => _isGeneratingMealPlan = false);
            }
          },
        ),
        const SizedBox(height: 12),
        AdhdToolCard(
          icon: Icons.self_improvement_rounded,
          title: 'Stretch Reset',
          subtitle: 'Use 30 seconds to loosen shoulders, neck, or wrists.',
          action: 'Start',
          onTap: () => widget.onMessage('Stretch reset started.'),
        ),
      ],
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.profile,
    required this.onEditProfile,
    required this.onSignOut,
  });

  final UserProfile profile;
  final VoidCallback onEditProfile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final birthday = profile.birthDate == null
        ? 'Not set'
        : '${profile.birthDate!.month.toString().padLeft(2, '0')}/${profile.birthDate!.day.toString().padLeft(2, '0')}/${profile.birthDate!.year}';

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: .18),
                foregroundColor: AppColors.blue,
                child: Text(
                  profile.firstName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      profile.email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
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
          const Divider(color: AppColors.border),
          const SizedBox(height: 4),
          _DetailRow(
            icon: Icons.cake_rounded,
            label: 'Birthday',
            value: birthday,
          ),
          _DetailRow(
            icon: Icons.payments_rounded,
            label: 'Currency',
            value: profile.currencyCode,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TourTarget(
                  id: 'me.edit',
                  child: FilledButton.icon(
                    onPressed: onEditProfile,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit Profile'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.storage_rounded,
            label: 'Data storage',
            value: 'Local database on this device',
          ),
          _DetailRow(
            icon: Icons.notifications_active_rounded,
            label: 'Smart Reminders',
            value: 'Requires notification permission',
          ),
          _DetailRow(
            icon: Icons.lock_rounded,
            label: 'Privacy',
            value: 'Local account',
          ),
        ],
      ),
    );
  }
}

class _ProfileArchiveCard extends StatelessWidget {
  const _ProfileArchiveCard({
    required this.financeMonths,
    required this.archivedInboxItems,
    required this.completedTasks,
  });

  final Map<int, FinanceMonth> financeMonths;
  final List<ArchivedInboxItem> archivedInboxItems;
  final List<PlannerTask> completedTasks;

  @override
  Widget build(BuildContext context) {
    final archivedPurchases = [
      for (final month in financeMonths.values)
        ...month.purchases.where((purchase) => purchase.archived),
    ]..sort((left, right) => right.date.compareTo(left.date));
    final sortedTasks = [...completedTasks]
      ..sort((left, right) => right.dueDate.compareTo(left.dueDate));
    final sortedInboxItems = [...archivedInboxItems]
      ..sort((left, right) => right.archivedAt.compareTo(left.archivedAt));
    final hasArchive =
        archivedPurchases.isNotEmpty ||
        sortedInboxItems.isNotEmpty ||
        sortedTasks.isNotEmpty;

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.archive_rounded, color: AppColors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Archive',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _ArchiveCountPill(
                count:
                    archivedPurchases.length +
                    sortedInboxItems.length +
                    sortedTasks.length,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Completed and archived items from finances, tasks, and brain dump.',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (!hasArchive)
            const _ArchiveEmptyState()
          else ...[
            _ArchiveSection(
              title: 'Finance Archive',
              emptyText: 'No archived purchases yet.',
              children: [
                for (final purchase in archivedPurchases)
                  _ArchiveTile(
                    icon: Icons.receipt_long_rounded,
                    title: purchase.description,
                    subtitle:
                        '${_formatFullDate(purchase.date)} • ${purchase.account} • ${purchase.category}',
                    trailing: formatCurrency(context, purchase.amount),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _ArchiveSection(
              title: 'Task Archive',
              emptyText: 'No completed tasks yet.',
              children: [
                for (final task in sortedTasks)
                  _ArchiveTile(
                    icon: Icons.task_alt_rounded,
                    title: task.name,
                    subtitle:
                        '${_formatFullDate(task.dueDate)} • ${task.priority} • ${task.category}',
                    trailing: task.status,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _ArchiveSection(
              title: 'Brain Dump Archive',
              emptyText: 'No archived brain dump items yet.',
              children: [
                for (final item in sortedInboxItems)
                  _ArchiveTile(
                    icon: Icons.inbox_rounded,
                    title: item.text,
                    subtitle: '${_formatDateTime(item.archivedAt)} • Archived',
                    trailing: 'Saved',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ArchiveCountPill extends StatelessWidget {
  const _ArchiveCountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$count Items',
        style: const TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ArchiveSection extends StatelessWidget {
  const _ArchiveSection({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (children.isEmpty)
            Text(
              emptyText,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (children.length <= 3)
            ...children
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 292),
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(children: children),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArchiveTile extends StatelessWidget {
  const _ArchiveTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            trailing,
            style: const TextStyle(
              color: AppColors.blue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveEmptyState extends StatelessWidget {
  const _ArchiveEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'No archived items yet. Archive purchases, brain dump items, or finish tasks to see them here.',
        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DietRoutineCard extends StatelessWidget {
  const _DietRoutineCard({
    required this.selectedDay,
    required this.isGenerating,
    required this.meals,
    required this.onDayChanged,
    required this.onAddMeal,
    required this.onEditMeal,
    required this.onAskAi,
  });

  final int selectedDay;
  final bool isGenerating;
  final List<DietMealPlan> meals;
  final ValueChanged<int> onDayChanged;
  final VoidCallback onAddMeal;
  final void Function(int index, DietMealPlan meal) onEditMeal;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu_rounded, color: AppColors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Food Planner',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TourTarget(
                id: 'fitness.ai',
                child: FilledButton.icon(
                  onPressed: isGenerating ? null : onAskAi,
                  icon: isGenerating
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(isGenerating ? 'Planning…' : 'Ask AI'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Plan ${_weekdayName(selectedDay)} meals around energy, workout timing, protein, and hydration.',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: selectedDay == day,
                      label: Text(_shortWeekdayName(day)),
                      avatar: selectedDay == day
                          ? const Icon(Icons.check_rounded, size: 16)
                          : null,
                      onSelected: (_) => onDayChanged(day),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TourTarget(
              id: 'fitness.meal',
              child: OutlinedButton.icon(
                key: const ValueKey('addMealButton'),
                onPressed: onAddMeal,
                icon: const Icon(Icons.add_rounded),
                label: Text('Add Meal For ${_weekdayName(selectedDay)}'),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MealGoalChip(icon: Icons.water_drop_rounded, label: 'Water'),
              _MealGoalChip(icon: Icons.egg_alt_rounded, label: 'Protein'),
              _MealGoalChip(icon: Icons.eco_rounded, label: 'Vegetables'),
              _MealGoalChip(
                icon: Icons.battery_charging_full_rounded,
                label: 'Workout Fuel',
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < meals.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MealPlanTile(
                icon: _mealIcon(meals[index].title),
                day: selectedDay,
                meal: meals[index],
                onEdit: () => onEditMeal(index, meals[index]),
              ),
            ),
          const SizedBox(height: 4),
          const _MealPrepNote(),
        ],
      ),
    );
  }

  static String _weekdayName(int day) {
    return switch (day) {
      DateTime.monday => 'Monday',
      DateTime.tuesday => 'Tuesday',
      DateTime.wednesday => 'Wednesday',
      DateTime.thursday => 'Thursday',
      DateTime.friday => 'Friday',
      DateTime.saturday => 'Saturday',
      DateTime.sunday => 'Sunday',
      _ => 'Today',
    };
  }

  static String _shortWeekdayName(int day) {
    return switch (day) {
      DateTime.monday => 'Mon',
      DateTime.tuesday => 'Tue',
      DateTime.wednesday => 'Wed',
      DateTime.thursday => 'Thu',
      DateTime.friday => 'Fri',
      DateTime.saturday => 'Sat',
      DateTime.sunday => 'Sun',
      _ => 'Day',
    };
  }

  static IconData _mealIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('breakfast')) {
      return Icons.wb_sunny_rounded;
    }
    if (lowerTitle.contains('lunch')) {
      return Icons.rice_bowl_rounded;
    }
    if (lowerTitle.contains('snack') || lowerTitle.contains('workout')) {
      return Icons.local_cafe_rounded;
    }
    if (lowerTitle.contains('hydration')) {
      return Icons.water_drop_rounded;
    }
    return Icons.dinner_dining_rounded;
  }
}

class _MealGoalChip extends StatelessWidget {
  const _MealGoalChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.blue, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealPlanTile extends ConsumerStatefulWidget {
  const _MealPlanTile({
    required this.icon,
    required this.meal,
    required this.onEdit,
    required this.day,
  });
  final IconData icon;
  final DietMealPlan meal;
  final VoidCallback onEdit;
  final int day;

  @override
  ConsumerState<_MealPlanTile> createState() => _MealPlanTileState();
}

class _MealPlanTileState extends ConsumerState<_MealPlanTile> {
  bool _estimating = false;

  Future<void> _estimate() async {
    final original = widget.meal;
    final day = widget.day;
    setState(() => _estimating = true);
    try {
      final nutrition = await const MealPlanAiService().estimateNutrition(
        original,
      );
      if (!mounted) return;
      final meals =
          ref.read(orbitControllerProvider).planner.dietPlans[day] ?? [];
      final index = meals.indexOf(original);
      // Ignore results if the meal was edited while the request was running.
      if (index >= 0) {
        ref
            .read(orbitControllerProvider.notifier)
            .updateDietMealPlan(
              day,
              index,
              original.copyWith(nutrition: nutrition),
            );
      }
    } on MealPlanAiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _estimating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, color: AppColors.blue, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  meal.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Edit Meal',
                onPressed: widget.onEdit,
                icon: const Icon(Icons.edit_rounded),
              ),
            ],
          ),
          Text(meal.time, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 6),
          Text(meal.focus),
          const SizedBox(height: 6),
          Text(meal.foods, style: const TextStyle(color: AppColors.softText)),
          const SizedBox(height: 6),
          Text(meal.notes, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          if (meal.nutrition != null)
            MealNutritionDetails(nutrition: meal.nutrition!)
          else ...[
            const Text('Calories & nutrients: not estimated yet.'),
            TextButton.icon(
              onPressed: _estimating ? null : _estimate,
              icon: _estimating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_outlined, size: 18),
              label: Text(
                _estimating ? 'Estimating…' : 'Estimate nutrition with AI',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MealPrepNote extends StatelessWidget {
  const _MealPrepNote();

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
      child: const Row(
        children: [
          Icon(Icons.checklist_rounded, color: AppColors.blue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Prep idea: choose tomorrow\'s protein, carb, and water bottle before bed.',
              style: TextStyle(
                color: AppColors.softText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }
}

Future<void> _captureBrainDump({
  required BuildContext context,
  required OrbitController controller,
  required ValueChanged<String> onMessage,
}) async {
  final item = await _showBrainDumpDialog(context);
  if (!context.mounted) {
    return;
  }
  if (item == null || item.isEmpty) {
    return;
  }
  controller.addInboxItem(item);
  onMessage('Saved To Brain Dump.');
}

void _showTopThreeDialog(
  BuildContext context,
  List<ScheduleBlock> blocks,
  int selectedIndex,
) {
  final dateLabel = _formatFullDate(DateTime.now());

  if (blocks.isEmpty) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.panel,
          title: Text('Top 3 Must Do Next - $dateLabel'),
          content: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No schedule items available.'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
    return;
  }

  final startIndex = selectedIndex.clamp(0, blocks.length - 1).toInt();
  final priorityBlocks = [
    ...blocks.skip(startIndex),
    ...blocks.take(startIndex),
  ].take(3).toList();

  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.panel,
        title: Text('Top 3 Must Do Next - $dateLabel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < priorityBlocks.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PriorityDialogTile(
                  number: index + 1,
                  block: priorityBlocks[index],
                  dateLabel: dateLabel,
                  reason: index == 0
                      ? 'Start here because it is selected now.'
                      : 'Next closest item in your schedule.',
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

void _showBreaksAddedDialog(
  BuildContext context,
  List<ScheduleBlock> addedBreaks,
  OrbitController controller,
  ValueChanged<String> onMessage,
) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.panel,
        title: Text(
          addedBreaks.isEmpty
              ? 'Breaks Already Added'
              : 'Breaks Added To Today',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              addedBreaks.isEmpty
                  ? 'Your Today timeline already has recovery breaks after the longer tasks.'
                  : 'I added ${addedBreaks.length} visible 10-minute break blocks after longer tasks.',
              style: const TextStyle(
                color: AppColors.softText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'How This Helps',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'It gives your brain a planned stopping point, so you can move, drink water, reset, and avoid task-to-task burnout.',
              style: TextStyle(
                color: AppColors.softText,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (addedBreaks.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final breakBlock in addedBreaks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.self_improvement_rounded,
                        color: AppColors.blue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${breakBlock.time} • ${breakBlock.title}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.clearTenMinuteBreaks();
              onMessage('Cleared break blocks from schedule.');
            },
            child: const Text('Clear Breaks'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('View Timeline'),
          ),
        ],
      );
    },
  );
}

void _showFocusGuideDialog(
  BuildContext context,
  String taskName,
  ValueChanged<String> onMessage,
) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Focus Session & Body Doubling'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('What It Is', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text(
              'Body doubling means working while another person is present, even quietly. It helps you start and stay on task.',
              style: TextStyle(
                color: AppColors.softText,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 14),
            _FocusGuideStep(
              number: '1',
              text: 'State your 1 goal out loud or to your partner.',
            ),
            _FocusGuideStep(
              number: '2',
              text: 'Set the live 25-minute Pomodoro timer.',
            ),
            _FocusGuideStep(
              number: '3',
              text: 'Work quietly without switching tabs/tasks.',
            ),
            _FocusGuideStep(
              number: '4',
              text: 'Take your 10-minute break when timer rings.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showLiveFocusRunner(context, taskName, onMessage);
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Start Focus Session'),
          ),
        ],
      );
    },
  );
}

void _showLiveFocusRunner(
  BuildContext context,
  String taskName,
  ValueChanged<String> onMessage,
) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return _FocusSessionRunnerDialog(
        taskName: taskName,
        onMessage: onMessage,
      );
    },
  );
}

class _FocusSessionRunnerDialog extends StatefulWidget {
  const _FocusSessionRunnerDialog({
    required this.taskName,
    required this.onMessage,
  });

  final String taskName;
  final ValueChanged<String> onMessage;

  @override
  State<_FocusSessionRunnerDialog> createState() =>
      _FocusSessionRunnerDialogState();
}

class _FocusSessionRunnerDialogState extends State<_FocusSessionRunnerDialog> {
  int _secondsLeft = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;
  DateTime? _targetEndTime;
  bool _step1Checked = false;
  bool _step2Checked = false;
  bool _step3Checked = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      SmartNotificationService.instance.cancelFocusTimerNotification();
      setState(() => _isRunning = false);
    } else {
      _targetEndTime = DateTime.now().add(Duration(seconds: _secondsLeft));
      SmartNotificationService.instance.scheduleFocusTimerNotification(
        taskName: widget.taskName,
        duration: Duration(seconds: _secondsLeft),
      );
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_targetEndTime == null) return;
        final diff = _targetEndTime!.difference(DateTime.now()).inSeconds;
        if (diff > 0) {
          setState(() => _secondsLeft = diff);
        } else {
          timer.cancel();
          SmartNotificationService.instance.cancelFocusTimerNotification();
          setState(() {
            _secondsLeft = 0;
            _isRunning = false;
          });
          widget.onMessage(
            '🎉 Focus Session Completed! Take your 10-minute break.',
          );
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    SmartNotificationService.instance.cancelFocusTimerNotification();
    setState(() {
      _secondsLeft = 25 * 60;
      _isRunning = false;
      _targetEndTime = null;
    });
  }

  String get _timeFormatted {
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = (25 * 60 - _secondsLeft) / (25 * 60);

    return AlertDialog(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: AppColors.blue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Focus Session & Body Doubling',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Text(
                    'FOCUS TASK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.taskName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _timeFormatted,
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.border,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _toggleTimer,
                        icon: Icon(
                          _isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(_isRunning ? 'Pause' : 'Start Focus'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _resetTimer,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Body Doubling Checklist',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            CheckboxListTile(
              value: _step1Checked,
              onChanged: (v) => setState(() => _step1Checked = v ?? false),
              title: const Text(
                'State your 1 goal to your partner / out loud',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            CheckboxListTile(
              value: _step2Checked,
              onChanged: (v) => setState(() => _step2Checked = v ?? false),
              title: const Text(
                'Work quietly without multitasking',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            CheckboxListTile(
              value: _step3Checked,
              onChanged: (v) => setState(() => _step3Checked = v ?? false),
              title: const Text(
                'Take a 10-minute break when timer rings',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onMessage('Focus session completed! Great job focusing.');
          },
          child: const Text('Complete Session'),
        ),
      ],
    );
  }
}

Future<String?> _showBrainDumpDialog(BuildContext context) {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Brain Dump'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Type the thought before it disappears',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

Future<double?> _showAmountDialog(
  BuildContext context, {
  required String title,
  required double initialValue,
}) {
  final controller = TextEditingController(
    text: initialValue == 0 ? '' : initialValue.toStringAsFixed(2),
  );

  return showDialog<double>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.panel,
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '${currencySymbolOf(context)} ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                double.tryParse(controller.text.trim()) ?? 0,
              );
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

Future<UserProfile?> _showEditProfileDialog(
  BuildContext context,
  UserProfile profile,
) {
  final nameController = TextEditingController(text: profile.displayName);
  var birthDate = profile.birthDate;
  var currencyCode = profile.currencyCode;

  return showDialog<UserProfile>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(Icons.cake_rounded),
                title: const Text('Birthday'),
                subtitle: Text(
                  birthDate == null
                      ? 'Not set'
                      : '${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.year}',
                ),
                trailing: const Icon(Icons.calendar_month_rounded),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: birthDate ?? DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (selected != null) {
                    setDialogState(() => birthDate = selected);
                  }
                },
              ),
              const SizedBox(height: 8),
              RoundedDropdownFormField<String>(
                value: currencyCode,
                decoration: const InputDecoration(
                  labelText: 'Default Currency',
                  prefixIcon: Icon(Icons.payments_rounded),
                ),
                menuMaxHeight: 280,
                itemHeight: 56,
                items: const [
                  DropdownMenuItem(value: 'PHP', child: Text('PHP - Peso')),
                  DropdownMenuItem(
                    value: 'USD',
                    child: Text('USD - US Dollar'),
                  ),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro')),
                  DropdownMenuItem(
                    value: 'GBP',
                    child: Text('GBP - British Pound'),
                  ),
                  DropdownMenuItem(
                    value: 'CAD',
                    child: Text('CAD - Canadian Dollar'),
                  ),
                  DropdownMenuItem(
                    value: 'AUD',
                    child: Text('AUD - Australian Dollar'),
                  ),
                  DropdownMenuItem(
                    value: 'JPY',
                    child: Text('JPY - Japanese Yen'),
                  ),
                  DropdownMenuItem(
                    value: 'SGD',
                    child: Text('SGD - Singapore Dollar'),
                  ),
                  DropdownMenuItem(
                    value: 'AED',
                    child: Text('AED - UAE Dirham'),
                  ),
                  DropdownMenuItem(
                    value: 'INR',
                    child: Text('INR - Indian Rupee'),
                  ),
                  DropdownMenuItem(
                    value: 'KRW',
                    child: Text('KRW - South Korean Won'),
                  ),
                  DropdownMenuItem(
                    value: 'CHF',
                    child: Text('CHF - Swiss Franc'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => currencyCode = value);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final displayName = nameController.text.trim();
              if (displayName.isEmpty) return;
              Navigator.pop(
                context,
                profile.copyWith(
                  displayName: displayName,
                  birthDate: birthDate,
                  currencyCode: currencyCode,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  ).whenComplete(nameController.dispose);
}

void _showPurchaseDetailDialog(
  BuildContext context,
  PurchaseEntry purchase,
  double balanceAfter,
) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Expense Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailRow(
              icon: Icons.shopping_bag_rounded,
              label: 'Item',
              value: purchase.description,
            ),
            _DetailRow(
              icon: Icons.payments_rounded,
              label: 'Spent',
              value: formatCurrency(context, purchase.amount),
            ),
            _DetailRow(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Paid With',
              value: purchase.account,
            ),
            _DetailRow(
              icon: Icons.savings_rounded,
              label: 'Balance After',
              value: formatCurrency(context, balanceAfter),
            ),
            _DetailRow(
              icon: Icons.calendar_month_rounded,
              label: 'Date And Time',
              value: _formatDateTime(purchase.date),
            ),
            _DetailRow(
              icon: Icons.category_rounded,
              label: 'Category',
              value: purchase.category,
            ),
            _DetailRow(
              icon: Icons.notes_rounded,
              label: 'Notes',
              value: purchase.notes.isEmpty ? 'No notes added' : purchase.notes,
            ),
            if (purchase.hasReceipt) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Receipt',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 280,
                child: purchase.receiptBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.memory(
                          purchase.receiptBytes!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : _ReceiptFallback(purchase: purchase),
              ),
            ] else ...[
              const SizedBox(height: 10),
              const _DetailRow(
                icon: Icons.receipt_long_rounded,
                label: 'Receipt',
                value: 'No receipt attached',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

void _showReceiptDialog(BuildContext context, PurchaseEntry purchase) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.panel,
        title: Text(purchase.receiptName ?? 'Receipt'),
        content: SizedBox(
          width: 320,
          child: purchase.receiptBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.memory(purchase.receiptBytes!),
                )
              : _ReceiptFallback(purchase: purchase),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

String _formatDateTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${date.month}/${date.day}/${date.year} at $hour:$minute $period';
}

String _formatFullDate(DateTime date) {
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

String _formatTaskTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

class _ReceiptFallback extends StatelessWidget {
  const _ReceiptFallback({required this.purchase});

  final PurchaseEntry purchase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            color: AppColors.primary,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            purchase.receiptName ?? 'Receipt attached',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            purchase.receiptPath ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

Future<PlannerTask?> _showPlannerTaskDialog(
  BuildContext context, {
  PlannerTask? initialTask,
  String initialStatus = 'To Do',
}) {
  final nameController = TextEditingController(text: initialTask?.name ?? '');
  var dueDate = initialTask?.dueDate ?? DateTime.now();
  var priority = initialTask?.priority ?? 'Medium';
  var category = initialTask?.category ?? 'Personal';
  var status = initialTask?.status ?? initialStatus;

  return showDialog<PlannerTask>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.panel,
            title: Text(
              initialTask == null ? 'Add $initialStatus Task' : 'Edit Task',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Task Name'),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.blue,
                    ),
                    title: const Text(
                      'Due Date',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(_formatFullDate(dueDate)),
                    trailing: TextButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 2),
                          ),
                        );
                        if (pickedDate != null) {
                          setDialogState(
                            () => dueDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              dueDate.hour,
                              dueDate.minute,
                            ),
                          );
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.blue,
                    ),
                    title: const Text(
                      'Deadline Time',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(_formatTaskTime(dueDate)),
                    trailing: TextButton(
                      onPressed: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(dueDate),
                        );
                        if (pickedTime != null) {
                          setDialogState(
                            () => dueDate = DateTime(
                              dueDate.year,
                              dueDate.month,
                              dueDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            ),
                          );
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  RoundedDropdownFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(value: 'High', child: Text('High')),
                      DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'Low', child: Text('Low')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => priority = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  RoundedDropdownFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'Work', child: Text('Work')),
                      DropdownMenuItem(
                        value: 'Personal',
                        child: Text('Personal'),
                      ),
                      DropdownMenuItem(
                        value: 'Finance',
                        child: Text('Finance'),
                      ),
                      DropdownMenuItem(value: 'Health', child: Text('Health')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => category = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  RoundedDropdownFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'To Do', child: Text('To Do')),
                      DropdownMenuItem(
                        value: 'In Progress',
                        child: Text('In Progress'),
                      ),
                      DropdownMenuItem(value: 'Done', child: Text('Done')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => status = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    return;
                  }
                  Navigator.pop(
                    context,
                    PlannerTask(
                      name: name,
                      dueDate: dueDate,
                      priority: priority,
                      category: category,
                      status: status,
                    ),
                  );
                },
                child: Text(initialTask == null ? 'Add Task' : 'Save Changes'),
              ),
            ],
          );
        },
      );
    },
  );
}

void _showTodayTaskDetailsDialog({
  required BuildContext context,
  required PlannerTask task,
  required VoidCallback onEdit,
  required VoidCallback onArchive,
}) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.panel,
        title: Row(
          children: [
            Expanded(
              child: Text(
                task.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Edit Task',
              onPressed: () {
                Navigator.pop(context);
                onEdit();
              },
              icon: const Icon(Icons.edit_rounded),
            ),
            const SizedBox(width: 6),
            IconButton.filledTonal(
              tooltip: 'Archive Task',
              onPressed: () {
                Navigator.pop(context);
                onArchive();
              },
              icon: const Icon(Icons.archive_rounded),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailRow(
              icon: Icons.flag_rounded,
              label: 'Status',
              value: task.status,
            ),
            _DetailRow(
              icon: Icons.calendar_month_rounded,
              label: 'Deadline',
              value:
                  '${_formatFullDate(task.dueDate)} at ${_formatTaskTime(task.dueDate)}',
            ),
            _DetailRow(
              icon: Icons.schedule_rounded,
              label: 'Time',
              value: _formatTaskTime(task.dueDate),
            ),
            _DetailRow(
              icon: Icons.priority_high_rounded,
              label: 'Priority',
              value: task.priority,
            ),
            _DetailRow(
              icon: Icons.category_rounded,
              label: 'Category',
              value: task.category,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

Future<MonthlyGoal?> _showMonthlyGoalDialog(
  BuildContext context,
  MonthlyGoal initialGoal, {
  bool isNew = false,
}) {
  final textController = TextEditingController(text: initialGoal.text);
  final targetController = TextEditingController(
    text: initialGoal.targetAmount == null
        ? ''
        : initialGoal.targetAmount!.toStringAsFixed(2),
  );
  var complete = initialGoal.complete;

  return showDialog<MonthlyGoal>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.panel,
            title: Text(isNew ? 'Add Monthly Goal' : 'Edit Monthly Goal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Goal Text'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Target Amount',
                      prefixText: '${currencySymbolOf(context)} ',
                      hintText: 'Optional',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: CheckboxListTile(
                      value: complete,
                      onChanged: (value) {
                        setDialogState(() => complete = value ?? false);
                      },
                      title: const Text(
                        'Completed',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final text = textController.text.trim();
                  if (text.isEmpty) {
                    return;
                  }
                  final targetText = targetController.text.trim();
                  Navigator.pop(
                    context,
                    MonthlyGoal(
                      id: initialGoal.id,
                      text: text,
                      complete: complete,
                      targetAmount: targetText.isEmpty
                          ? null
                          : double.tryParse(targetText),
                    ),
                  );
                },
                child: Text(isNew ? 'Add Goal' : 'Save Goal'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<DietMealPlan?> _showDietMealDialog(
  BuildContext context,
  DietMealPlan initialMeal, {
  bool isNew = false,
}) {
  final titleController = TextEditingController(text: initialMeal.title);
  final timeController = TextEditingController(text: initialMeal.time);
  final focusController = TextEditingController(text: initialMeal.focus);
  final foodsController = TextEditingController(text: initialMeal.foods);
  final notesController = TextEditingController(text: initialMeal.notes);

  return showDialog<DietMealPlan>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.panel,
        title: Text(isNew ? 'Add Meal' : 'Edit Meal Plan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Meal Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Time'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: focusController,
                decoration: const InputDecoration(
                  labelText: 'Focus',
                  hintText: 'Protein, energy, recovery...',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: foodsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Foods To Eat',
                  hintText: 'Chicken, rice, vegetables...',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Prep reminder, portion idea, water...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                return;
              }
              Navigator.pop(
                context,
                DietMealPlan(
                  nutrition:
                      title == initialMeal.title &&
                          foodsController.text.trim() == initialMeal.foods &&
                          notesController.text.trim() == initialMeal.notes
                      ? initialMeal.nutrition
                      : null,
                  id: initialMeal.id,
                  dayId: initialMeal.dayId,
                  title: title,
                  time: timeController.text.trim().isEmpty
                      ? 'Anytime'
                      : timeController.text.trim(),
                  focus: focusController.text.trim().isEmpty
                      ? 'Balanced Meal'
                      : focusController.text.trim(),
                  foods: foodsController.text.trim().isEmpty
                      ? 'Add foods here'
                      : foodsController.text.trim(),
                  notes: notesController.text.trim().isEmpty
                      ? 'No notes yet.'
                      : notesController.text.trim(),
                ),
              );
            },
            child: Text(isNew ? 'Add Meal' : 'Save Meal'),
          ),
        ],
      );
    },
  );
}

String _weekdayNameFor(int day) {
  return switch (day) {
    DateTime.monday => 'Monday',
    DateTime.tuesday => 'Tuesday',
    DateTime.wednesday => 'Wednesday',
    DateTime.thursday => 'Thursday',
    DateTime.friday => 'Friday',
    DateTime.saturday => 'Saturday',
    DateTime.sunday => 'Sunday',
    _ => 'Today',
  };
}

Future<MealPlanAiRequest?> _showAiMealPlanDialog(
  BuildContext context,
  String dayName,
) {
  return showDialog<MealPlanAiRequest>(
    context: context,
    builder: (context) => _AiMealPlanDialog(dayName: dayName),
  );
}

class _AiMealPlanDialog extends StatefulWidget {
  const _AiMealPlanDialog({required this.dayName});

  final String dayName;

  @override
  State<_AiMealPlanDialog> createState() => _AiMealPlanDialogState();
}

class _AiMealPlanDialogState extends State<_AiMealPlanDialog> {
  late final TextEditingController _goalController;
  late final TextEditingController _dietController;
  late final TextEditingController _allergyController;
  var _budgetStyle = 'Budget friendly';
  var _mealCount = 3;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController(
      text: 'Balanced energy and healthier everyday eating',
    );
    _dietController = TextEditingController(text: 'No preference');
    _allergyController = TextEditingController(text: 'None');
  }

  @override
  void dispose() {
    _goalController.dispose();
    _dietController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.panel,
      title: Text('AI Meal Plan For ${widget.dayName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.chip,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.privacy_tip_outlined, size: 19),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Your answers are sent to an AI provider. Avoid entering medical records or other sensitive details.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _goalController,
              decoration: const InputDecoration(
                labelText: 'Healthy Living Goal',
                hintText: 'Balanced energy, more vegetables...',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dietController,
              decoration: const InputDecoration(
                labelText: 'Dietary Preference',
                hintText: 'Vegetarian, high protein, no preference...',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _allergyController,
              decoration: const InputDecoration(
                labelText: 'Allergies Or Foods To Avoid',
                hintText: 'None, peanuts, shellfish...',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _budgetStyle,
              decoration: const InputDecoration(labelText: 'Budget Style'),
              items: const [
                DropdownMenuItem(
                  value: 'Budget friendly',
                  child: Text('Budget friendly'),
                ),
                DropdownMenuItem(value: 'Flexible', child: Text('Flexible')),
                DropdownMenuItem(
                  value: 'Minimal cooking',
                  child: Text('Minimal cooking'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _budgetStyle = value);
                }
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: _mealCount,
              decoration: const InputDecoration(labelText: 'Meals'),
              items: const [
                DropdownMenuItem(value: 2, child: Text('2 meals')),
                DropdownMenuItem(value: 3, child: Text('3 meals')),
                DropdownMenuItem(value: 4, child: Text('4 meals')),
                DropdownMenuItem(value: 5, child: Text('5 meals')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _mealCount = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(
              context,
              MealPlanAiRequest(
                dayName: widget.dayName,
                goal: _goalController.text.trim(),
                dietaryPreference: _dietController.text.trim(),
                allergies: _allergyController.text.trim(),
                budgetStyle: _budgetStyle,
                mealCount: _mealCount,
              ),
            );
          },
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Generate'),
        ),
      ],
    );
  }
}

Future<bool?> _showAiMealPlanPreview(
  BuildContext context,
  List<DietMealPlan> meals,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.panel,
      title: const Text('Review Meal Ideas'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final meal in meals)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${meal.time} • ${meal.title}',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(meal.foods),
                      if (meal.nutrition != null)
                        MealNutritionDetails(nutrition: meal.nutrition!),
                      const SizedBox(height: 4),
                      Text(
                        meal.notes,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              const Text(
                'AI suggestions are general ideas, not medical or nutritional advice.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Discard'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('Add To Plan'),
        ),
      ],
    ),
  );
}

void _showOrganizeSheet(BuildContext context, ValueChanged<String> onMessage) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.panel,
    showDragHandle: true,
    builder: (context) {
      return _ActionSheet(
        title: 'Organize Today',
        actions: [
          _SheetAction(Icons.filter_3_rounded, 'Show Top 3 Only', () {
            Navigator.pop(context);
            onMessage('Top 3 view is ready.');
          }),
          _SheetAction(Icons.timer_10_rounded, 'Add Buffers', () {
            Navigator.pop(context);
            onMessage('10-minute buffers added.');
          }),
          _SheetAction(Icons.schedule_rounded, 'Move Low-Energy Tasks', () {
            Navigator.pop(context);
            onMessage('Low-energy tasks moved later.');
          }),
        ],
      );
    },
  );
}

void _showReminderSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const _ReminderPreviewSheet(),
  );
}

class _ReminderPreviewSheet extends StatelessWidget {
  const _ReminderPreviewSheet();

  static const _reminders = [
    (
      '8:25',
      'Morning reset',
      'Start your morning reset now.',
      Icons.wb_sunny_rounded,
    ),
    (
      '8:40',
      'Transition break',
      'Take a moment before your next task.',
      Icons.spa_rounded,
    ),
    (
      '10:00',
      'Admin pocket',
      'Pay your phone bill.',
      Icons.receipt_long_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.activeCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upcoming reminders',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '3 scheduled for this morning',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close reminders',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              for (var index = 0; index < _reminders.length; index++)
                _ReminderPreviewItem(
                  time: _reminders[index].$1,
                  title: _reminders[index].$2,
                  description: _reminders[index].$3,
                  icon: _reminders[index].$4,
                  isLast: index == _reminders.length - 1,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderPreviewItem extends StatelessWidget {
  const _ReminderPreviewItem({
    required this.time,
    required this.title,
    required this.description,
    required this.icon,
    required this.isLast,
  });

  final String time;
  final String title;
  final String description;
  final IconData icon;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 58,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.chip,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    time,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.panel.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.7),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 19, color: AppColors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.softText,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showResetSheet(BuildContext context) {
  _showInfoSheet(
    context,
    title: 'Breathe And Choose One Task',
    icon: Icons.self_improvement_rounded,
    lines: const [
      'Unclench your jaw.',
      'Drop your shoulders.',
      'Pick one tiny next action.',
    ],
  );
}

void _showInfoSheet(
  BuildContext context, {
  required String title,
  required IconData icon,
  required List<String> lines,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.panel,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints.tightFor(
      width: MediaQuery.sizeOf(context).width,
    ),
    builder: (context) {
      return SizedBox(
        width: double.infinity,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final line in lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        line,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.softText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({required this.title, required this.actions});

  final String title;
  final List<_SheetAction> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (final action in actions)
            ListTile(
              onTap: action.onTap,
              leading: Icon(action.icon, color: AppColors.primary),
              title: Text(
                action.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _SheetAction {
  const _SheetAction(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
