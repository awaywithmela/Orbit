import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_database.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/app_tab.dart';
import '../domain/finance_models.dart';
import '../domain/planner_models.dart';
import '../domain/schedule_block.dart';
import 'orbit_state.dart';

final orbitControllerProvider = NotifierProvider<OrbitController, OrbitState>(
  OrbitController.new,
);

class OrbitController extends Notifier<OrbitState> {
  static const _key = 'orbit.state';

  @override
  OrbitState build() {
    final initial = OrbitState(
      selectedTab: AppTab.today,
      selectedBlockIndex: 0,
      snoozeCount: 0,
      focusStarted: false,
      inboxItems: const [],
      archivedInboxItems: const [],
      selectedMonth: DateTime.now().month,
      financeMonths: _defaultFinanceMonths(),
      planner: PlannerState(
        tasks: const [],
        goals: const [],
        notes: const [],
        dietPlans: const {},
      ),
      todayBlocks: const [],
    );
    Future.microtask(() async {
      final raw = await LocalDatabase.instance.read(_key);
      if (raw != null) _restore(jsonDecode(raw));
    });
    return initial;
  }

  Future<void> refreshLocal() async => _loadLocal();
  Future<void> _loadLocal() async {}

  void selectTab(AppTab tab) {
    state = state.copyWith(selectedTab: tab);
    _save();
  }

  void selectScheduleBlock(int index) {
    state = state.copyWith(selectedBlockIndex: index, focusStarted: false);
    _save();
  }

  void startFocus() {
    state = state.copyWith(focusStarted: true);
    _save();
  }

  void snoozeFocus() {
    state = state.copyWith(
      snoozeCount: state.snoozeCount + 1,
      focusStarted: false,
    );
    _save();
  }

  void toggleTopThreeOnly([bool? value]) {
    state = state.copyWith(showTopThreeOnly: value ?? !state.showTopThreeOnly);
    _save();
  }

  void addTask(ScheduleBlock block) {
    final blocks = [...state.todayBlocks, block];
    state = state.copyWith(
      todayBlocks: blocks,
      selectedBlockIndex: blocks.length - 1,
      selectedTab: AppTab.today,
    );
    _save();
  }

  List<ScheduleBlock> addTenMinuteBreaks() {
    final result = <ScheduleBlock>[];
    for (final block in state.todayBlocks) {
      result.add(block);
      if (block.title != '10-Minute Break') result.add(_breakAfter(block));
    }
    state = state.copyWith(todayBlocks: result, selectedBlockIndex: 0);
    _save();
    return result;
  }

  void clearTenMinuteBreaks() {
    state = state.copyWith(
      todayBlocks: state.todayBlocks
          .where((b) => b.title != '10-Minute Break')
          .toList(),
    );
    _save();
  }

  void addInboxItem(String item) {
    final value = item.trim();
    if (value.isEmpty) return;
    state = state.copyWith(inboxItems: [value, ...state.inboxItems]);
    _save();
  }

  void archiveInboxItem(String item) {
    state = state.copyWith(
      inboxItems: state.inboxItems.where((x) => x != item).toList(),
      archivedInboxItems: [
        ArchivedInboxItem(text: item, archivedAt: DateTime.now()),
        ...state.archivedInboxItems,
      ],
    );
    _save();
  }

  void selectMonth(int month) {
    state = state.copyWith(selectedMonth: month);
    _save();
  }

  void updateAccountBalance(String name, double balance) {
    final month = state.currentFinanceMonth;
    _setMonth(
      month.copyWith(
        accounts: [
          for (final a in month.accounts)
            a.name == name ? a.copyWith(initialBalance: balance) : a,
        ],
      ),
    );
  }

  Future<bool> addAccount(BankAccount account) async {
    final month = state.currentFinanceMonth;
    if (month.accounts.any(
      (a) => a.name.toLowerCase() == account.name.toLowerCase(),
    ))
      return false;
    _setMonth(
      month.copyWith(accounts: [...month.accounts, account.copyWith()]),
      save: true,
    );
    return true;
  }

  void updateCategoryBudget(String name, double budget) {
    final month = state.currentFinanceMonth;
    _setMonth(
      month.copyWith(
        categoryBudgets: [
          for (final c in month.categoryBudgets)
            c.name == name ? c.copyWith(monthlyBudget: budget) : c,
        ],
      ),
    );
  }

  Future<bool> addExpenseCategory({
    required String name,
    required Color color,
    required double monthlyBudget,
  }) async {
    final value = name.trim();
    final month = state.currentFinanceMonth;
    if (value.isEmpty ||
        monthlyBudget < 0 ||
        month.categoryBudgets.any(
          (c) => c.name.toLowerCase() == value.toLowerCase(),
        ))
      return false;
    _setMonth(
      month.copyWith(
        categoryBudgets: [
          ...month.categoryBudgets,
          CategoryBudget(name: value, monthlyBudget: monthlyBudget),
        ],
      ),
      save: true,
    );
    return true;
  }

  Future<bool> addPurchase(PurchaseEntry entry) async {
    final month = state.currentFinanceMonth;
    if (month.purchases.length >= 100 ||
        !month.accounts.any((a) => a.name == entry.account) ||
        !month.categoryBudgets.any((c) => c.name == entry.category))
      return false;
    _setMonth(
      month.copyWith(purchases: [...month.purchases, entry]),
      save: true,
    );
    return true;
  }

  void archivePurchase(PurchaseEntry entry) {
    _setMonth(
      state.currentFinanceMonth.copyWith(
        purchases: [
          for (final p in state.currentFinanceMonth.purchases)
            identical(p, entry) ? p.copyWith(archived: true) : p,
        ],
      ),
    );
  }

  void addPlannerTask(PlannerTask task) {
    _setPlanner(state.planner.copyWith(tasks: [task, ...state.planner.tasks]));
  }

  void updatePlannerTask(PlannerTask oldTask, PlannerTask updated) {
    _setPlanner(
      state.planner.copyWith(
        tasks: [
          for (final t in state.planner.tasks)
            identical(t, oldTask) ? updated : t,
        ],
      ),
    );
  }

  void updatePlannerTaskStatus(PlannerTask task, String status) =>
      updatePlannerTask(task, task.copyWith(status: status));
  void archivePlannerTask(PlannerTask task) => updatePlannerTask(
    task,
    task.copyWith(status: 'Archived', archivedAt: DateTime.now()),
  );
  void toggleGoal(int index) {
    final goals = [...state.planner.goals];
    if (index < 0 || index >= goals.length) return;
    goals[index] = goals[index].copyWith(complete: !goals[index].complete);
    _setPlanner(state.planner.copyWith(goals: goals));
  }

  void addMonthlyGoal(MonthlyGoal goal) => _setPlanner(
    state.planner.copyWith(goals: [...state.planner.goals, goal]),
  );
  void updateMonthlyGoal(int index, MonthlyGoal goal) {
    final goals = [...state.planner.goals];
    if (index < 0 || index >= goals.length) return;
    goals[index] = goal;
    _setPlanner(state.planner.copyWith(goals: goals));
  }

  void addPlannerNote(String body) {
    final value = body.trim();
    if (value.isEmpty) return;
    _setPlanner(
      state.planner.copyWith(
        notes: [
          ...state.planner.notes,
          PlannerNote(
            id: 'local-${DateTime.now().microsecondsSinceEpoch}',
            body: value,
            createdAt: DateTime.now(),
          ),
        ],
      ),
    );
  }

  void deletePlannerNote(PlannerNote note) => _setPlanner(
    state.planner.copyWith(
      notes: state.planner.notes.where((n) => n.id != note.id).toList(),
    ),
  );

  void updateDietMealPlan(int day, int index, DietMealPlan meal) {
    final meals = [...?state.planner.dietPlans[day]];
    if (index < 0 || index >= meals.length) return;
    meals[index] = meal;
    _setPlanner(
      state.planner.copyWith(
        dietPlans: {...state.planner.dietPlans, day: meals},
      ),
    );
  }

  void addDietMealPlan(int day, DietMealPlan meal) {
    _setPlanner(
      state.planner.copyWith(
        dietPlans: {
          ...state.planner.dietPlans,
          day: [...?state.planner.dietPlans[day], meal],
        },
      ),
    );
  }

  Future<bool> addDietMealPlans(int day, List<DietMealPlan> meals) async {
    if (meals.isEmpty) return false;
    _setPlanner(
      state.planner.copyWith(
        dietPlans: {
          ...state.planner.dietPlans,
          day: [...?state.planner.dietPlans[day], ...meals],
        },
      ),
    );
    return true;
  }

  void _setMonth(FinanceMonth month, {bool save = true}) {
    state = state.copyWith(
      financeMonths: {...state.financeMonths, state.selectedMonth: month},
    );
    if (save) _save();
  }

  void _setPlanner(PlannerState planner) {
    state = state.copyWith(planner: planner);
    _save();
  }

  void _save() {
    unawaited(LocalDatabase.instance.write(_key, jsonEncode(_stateJson())));
  }

  Map<String, dynamic> _stateJson() => {
    'tab': state.selectedTab.name,
    'block': state.selectedBlockIndex,
    'snooze': state.snoozeCount,
    'focus': state.focusStarted,
    'topThree': state.showTopThreeOnly,
    'month': state.selectedMonth,
    'inbox': state.inboxItems,
    'archivedInbox': [
      for (final x in state.archivedInboxItems)
        {'text': x.text, 'at': x.archivedAt.toIso8601String()},
    ],
    'blocks': [for (final x in state.todayBlocks) _blockJson(x)],
    'finance': {
      for (final e in state.financeMonths.entries)
        e.key.toString(): _financeJson(e.value),
    },
    'planner': _plannerJson(state.planner),
  };

  void _restore(dynamic raw) {
    if (raw is! Map) return;
    state = state.copyWith(
      selectedTab:
          AppTab.values.where((x) => x.name == raw['tab']).firstOrNull ??
          AppTab.today,
      selectedBlockIndex: raw['block'] as int? ?? 0,
      snoozeCount: raw['snooze'] as int? ?? 0,
      focusStarted: raw['focus'] as bool? ?? false,
      showTopThreeOnly: raw['topThree'] as bool? ?? false,
      selectedMonth: raw['month'] as int? ?? DateTime.now().month,
      inboxItems: [
        for (final x in (raw['inbox'] as List? ?? const [])) x.toString(),
      ],
      planner: state.planner.copyWith(dietPlans: _restoreMeals(raw['planner'])),
      archivedInboxItems: const [],
      todayBlocks: const [],
    );
  }

  static Map<int, List<DietMealPlan>> _restoreMeals(dynamic planner) {
    if (planner is! Map || planner['diet'] is! Map) return {};
    final result = <int, List<DietMealPlan>>{};
    for (final entry in (planner['diet'] as Map).entries) {
      final day = int.tryParse(entry.key.toString());
      if (day == null || entry.value is! List) continue;
      result[day] = [];
      for (final meal in entry.value as List) {
        if (meal is! Map) continue;
        MealNutrition? nutrition;
        try {
          if (meal['nutrition'] != null)
            nutrition = MealNutrition.fromJson(meal['nutrition']);
        } on FormatException {
          /* Keep older meals even if estimates are invalid. */
        }
        result[day]!.add(
          DietMealPlan(
            id: meal['id'] as String?,
            dayId: meal['day'] as String?,
            title: meal['title']?.toString() ?? '',
            time: meal['time']?.toString() ?? '',
            focus: meal['focus']?.toString() ?? '',
            foods: meal['foods']?.toString() ?? '',
            notes: meal['notes']?.toString() ?? '',
            nutrition: nutrition,
          ),
        );
      }
    }
    return result;
  }

  static Map<String, dynamic> _blockJson(ScheduleBlock x) => {
    'id': x.id,
    'time': x.time,
    'title': x.title,
    'description': x.description,
    'details': x.details,
    'duration': x.duration,
    'icon': x.icon.codePoint,
    'color': x.color.toARGB32(),
  };
  static Map<String, dynamic> _financeJson(FinanceMonth x) => {
    'accounts': [
      for (final a in x.accounts)
        {
          'id': a.id,
          'name': a.name,
          'balance': a.initialBalance,
          'color': a.color.toARGB32(),
        },
    ],
    'categories': [
      for (final c in x.categoryBudgets)
        {
          'id': c.id,
          'categoryId': c.categoryId,
          'name': c.name,
          'budget': c.monthlyBudget,
        },
    ],
    'purchases': [
      for (final p in x.purchases)
        {
          'id': p.id,
          'accountId': p.accountId,
          'categoryId': p.categoryId,
          'date': p.date.toIso8601String(),
          'description': p.description,
          'category': p.category,
          'amount': p.amount,
          'account': p.account,
          'notes': p.notes,
          'archived': p.archived,
        },
    ],
  };
  static Map<String, dynamic> _plannerJson(PlannerState x) => {
    'tasks': [
      for (final t in x.tasks)
        {
          'id': t.id,
          'name': t.name,
          'due': t.dueDate.toIso8601String(),
          'priority': t.priority,
          'category': t.category,
          'status': t.status,
          'archived': t.archivedAt?.toIso8601String(),
        },
    ],
    'goals': [
      for (final g in x.goals)
        {
          'id': g.id,
          'text': g.text,
          'complete': g.complete,
          'target': g.targetAmount,
        },
    ],
    'notes': [
      for (final n in x.notes)
        {'id': n.id, 'body': n.body, 'at': n.createdAt.toIso8601String()},
    ],
    'diet': {
      for (final e in x.dietPlans.entries)
        e.key.toString(): [
          for (final m in e.value)
            {
              'id': m.id,
              'day': m.dayId,
              'title': m.title,
              'time': m.time,
              'focus': m.focus,
              'foods': m.foods,
              'notes': m.notes,
              'nutrition': m.nutrition?.toJson(),
            },
        ],
    },
  };
  static Map<int, FinanceMonth> _defaultFinanceMonths() {
    final result = _emptyFinanceMonths();
    result[DateTime.now().month] = const FinanceMonth(
      accounts: [
        BankAccount(name: 'Cash', initialBalance: 0, color: AppColors.blue),
      ],
      categoryBudgets: [
        CategoryBudget(name: 'Food', monthlyBudget: 0),
        CategoryBudget(name: 'Transport', monthlyBudget: 0),
        CategoryBudget(name: 'Bills', monthlyBudget: 0),
        CategoryBudget(name: 'Shopping', monthlyBudget: 0),
        CategoryBudget(name: 'Health', monthlyBudget: 0),
        CategoryBudget(name: 'Other', monthlyBudget: 0),
      ],
      purchases: [],
    );
    return result;
  }

  static Map<int, FinanceMonth> _emptyFinanceMonths() => {
    for (var m = 1; m <= 12; m++)
      m: const FinanceMonth(accounts: [], categoryBudgets: [], purchases: []),
  };
  static ScheduleBlock _breakAfter(ScheduleBlock block) => ScheduleBlock(
    time: 'After ${block.time}',
    title: '10-Minute Break',
    description: 'Move, hydrate, and reset attention.',
    details: 'Stand up, drink water, stretch, then choose the next step.',
    duration: '10m',
    icon: Icons.self_improvement_rounded,
    color: AppColors.pastelMint,
  );
}
