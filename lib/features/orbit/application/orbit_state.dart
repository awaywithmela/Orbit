import '../domain/app_tab.dart';
import '../domain/finance_models.dart';
import '../domain/planner_models.dart';
import '../domain/schedule_block.dart';

class OrbitState {
  OrbitState({
    required this.selectedTab,
    required this.selectedBlockIndex,
    required this.snoozeCount,
    required this.focusStarted,
    required this.inboxItems,
    required Object? archivedInboxItems,
    required this.selectedMonth,
    required this.financeMonths,
    required this.planner,
    required this.todayBlocks,
    this.showTopThreeOnly = false,
  }) : _archivedInboxItems = archivedInboxItems;

  final AppTab selectedTab;
  final int selectedBlockIndex;
  final int snoozeCount;
  final bool focusStarted;
  final List<String> inboxItems;
  final Object? _archivedInboxItems;
  final int selectedMonth;
  final Map<int, FinanceMonth> financeMonths;
  final PlannerState planner;
  final List<ScheduleBlock> todayBlocks;
  final bool showTopThreeOnly;

  ScheduleBlock? get selectedBlock {
    if (todayBlocks.isEmpty) {
      return null;
    }
    final safeIndex = selectedBlockIndex.clamp(0, todayBlocks.length - 1);
    return todayBlocks[safeIndex];
  }

  List<ScheduleBlock> get visibleTodayBlocks {
    if (!showTopThreeOnly || todayBlocks.isEmpty) {
      return todayBlocks;
    }
    final safeIndex = selectedBlockIndex.clamp(0, todayBlocks.length - 1);
    return [
      ...todayBlocks.skip(safeIndex),
      ...todayBlocks.take(safeIndex),
    ].take(3).toList();
  }

  FinanceMonth get currentFinanceMonth {
    return financeMonths[selectedMonth] ??
        const FinanceMonth(accounts: [], categoryBudgets: [], purchases: []);
  }

  List<ArchivedInboxItem> get archivedInboxItems {
    final items = _archivedInboxItems;
    if (items is List<ArchivedInboxItem>) {
      return items;
    }
    if (items is List<String>) {
      return [
        for (final item in items)
          ArchivedInboxItem(text: item, archivedAt: DateTime.now()),
      ];
    }
    if (items is List) {
      return [
        for (final item in items)
          if (item is ArchivedInboxItem)
            item
          else if (item is String)
            ArchivedInboxItem(text: item, archivedAt: DateTime.now()),
      ];
    }
    return const [];
  }

  OrbitState copyWith({
    AppTab? selectedTab,
    int? selectedBlockIndex,
    int? snoozeCount,
    bool? focusStarted,
    List<String>? inboxItems,
    List<ArchivedInboxItem>? archivedInboxItems,
    int? selectedMonth,
    Map<int, FinanceMonth>? financeMonths,
    PlannerState? planner,
    List<ScheduleBlock>? todayBlocks,
    bool? showTopThreeOnly,
  }) {
    return OrbitState(
      selectedTab: selectedTab ?? this.selectedTab,
      selectedBlockIndex: selectedBlockIndex ?? this.selectedBlockIndex,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      focusStarted: focusStarted ?? this.focusStarted,
      inboxItems: inboxItems ?? this.inboxItems,
      archivedInboxItems: archivedInboxItems ?? this.archivedInboxItems,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      financeMonths: financeMonths ?? this.financeMonths,
      planner: planner ?? this.planner,
      todayBlocks: todayBlocks ?? this.todayBlocks,
      showTopThreeOnly: showTopThreeOnly ?? this.showTopThreeOnly,
    );
  }
}
