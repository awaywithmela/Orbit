import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/app_tab.dart';

class OrbitBottomNav extends StatelessWidget {
  const OrbitBottomNav({
    required this.selectedTab,
    required this.onChanged,
    super.key,
  });

  final AppTab selectedTab;
  final ValueChanged<AppTab> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (AppTab.today, Icons.home_outlined, 'Today'),
      (AppTab.plan, Icons.calendar_month_outlined, 'Plan'),
      (AppTab.expenses, Icons.account_balance_wallet_outlined, 'Expense'),
      (AppTab.fitness, Icons.fitness_center_rounded, 'Fitness'),
      (AppTab.me, Icons.person_outline_rounded, 'Me'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: Semantics(
                      selected: selectedTab == item.$1,
                      button: true,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onChanged(item.$1),
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedTab == item.$1
                                  ? AppColors.text
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.$2,
                                  size: 22,
                                  color: selectedTab == item.$1
                                      ? Colors.white
                                      : AppColors.muted,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  item.$3,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: selectedTab == item.$1
                                            ? Colors.white
                                            : AppColors.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
