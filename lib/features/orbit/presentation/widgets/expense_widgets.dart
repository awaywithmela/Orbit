import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/formatting/currency_format.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/finance_models.dart';

const _purchaseTableWidth = 960.0;
const _purchaseDateWidth = 72.0;
const _purchaseItemWidth = 160.0;
const _purchaseCategoryWidth = 122.0;
const _purchaseAmountWidth = 96.0;
const _purchaseBankWidth = 96.0;
const _purchaseBalanceWidth = 128.0;
const _purchaseNotesWidth = 170.0;
const _purchaseActionWidth = 44.0;

const monthLabels = [
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

class AccountBalanceStrip extends StatelessWidget {
  const AccountBalanceStrip({
    required this.month,
    required this.onAddPurchaseForAccount,
    required this.onEditBalance,
    super.key,
  });

  final FinanceMonth month;
  final void Function(BankAccount account) onAddPurchaseForAccount;
  final void Function(BankAccount account) onEditBalance;

  @override
  Widget build(BuildContext context) {
    if (month.accounts.isEmpty) {
      return Container(
        height: 148,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.blue,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              'No wallets to show yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap New Wallet above to add your first bank or cash account.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 188,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: month.accounts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final account = month.accounts[index];
          final spent = month.accountSpent(account.name);
          final balance = month.accountBalance(account.name);
          return _AccountCard(
            account: account,
            spent: spent,
            balance: balance,
            onAddExpense: () => onAddPurchaseForAccount(account),
            onEditBalance: () => onEditBalance(account),
          );
        },
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.spent,
    required this.balance,
    required this.onAddExpense,
    required this.onEditBalance,
  });

  final BankAccount account;
  final double spent;
  final double balance;
  final VoidCallback onAddExpense;
  final VoidCallback onEditBalance;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAddExpense,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 244,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: account.color.withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: account.color.withValues(alpha: 0.85),
                    ),
                  ),
                  child: Text(
                    account.name,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Edit Starting Money',
                  onPressed: onEditBalance,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatCurrency(context, balance),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: balance < 0 ? AppColors.blue : AppColors.text,
                ),
              ),
            ),
            Text(
              'Balance Now',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _MoneyLine(label: 'Bank Spent', amount: spent),
          ],
        ),
      ),
    );
  }
}

class FinanceOverview extends StatelessWidget {
  const FinanceOverview({required this.month, super.key});

  final FinanceMonth month;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.activeCard,
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
              Text(
                'Total Wallet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatCurrency(context, month.totalWealth),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: month.initialBalance <= 0
                    ? 0
                    : (month.totalWealth / month.initialBalance).clamp(0, 1),
                minHeight: 10,
                borderRadius: BorderRadius.circular(999),
                backgroundColor: AppColors.chip,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _BigMoneyCard(
                title: 'Initial Balance',
                amount: month.initialBalance,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BigMoneyCard(
                title: 'Total Spent',
                amount: month.totalSpent,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BigMoneyCard(
                title: 'Current Balance',
                amount: month.currentBalance,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class MonthSelector extends StatelessWidget {
  const MonthSelector({
    required this.selectedMonth,
    required this.onChanged,
    super.key,
  });

  final int selectedMonth;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: monthLabels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final month = index + 1;
          final selected = month == selectedMonth;
          return ChoiceChip(
            selected: selected,
            label: Text(monthLabels[index]),
            selectedColor: AppColors.primary,
            onSelected: (_) => onChanged(month),
          );
        },
      ),
    );
  }
}

class CategoryBudgetTable extends StatelessWidget {
  const CategoryBudgetTable({
    required this.month,
    required this.onEditBudget,
    super.key,
  });

  final FinanceMonth month;
  final ValueChanged<CategoryBudget> onEditBudget;

  @override
  Widget build(BuildContext context) {
    final spending = month.spendingByCategory;
    return _Panel(
      title: 'Spending by Category',
      child: Column(
        children: [
          for (final budget in month.categoryBudgets)
            _CategoryRow(
              budget: budget,
              spent: spending[budget.name] ?? 0,
              onTap: () => onEditBudget(budget),
            ),
        ],
      ),
    );
  }
}

class PurchaseLogTable extends StatelessWidget {
  const PurchaseLogTable({
    required this.month,
    required this.onAddPurchase,
    required this.onArchivePurchase,
    required this.onViewPurchase,
    required this.onViewReceipt,
    super.key,
  });

  final FinanceMonth month;
  final VoidCallback onAddPurchase;
  final ValueChanged<PurchaseEntry> onArchivePurchase;
  final void Function(PurchaseEntry purchase, double balanceAfter)
  onViewPurchase;
  final ValueChanged<PurchaseEntry> onViewReceipt;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Purchase Log (${month.activePurchases.length}/100)',
      trailing: IconButton.filled(
        onPressed: onAddPurchase,
        icon: const Icon(Icons.add_rounded),
        tooltip: 'Add Expense',
        style: IconButton.styleFrom(
          fixedSize: const Size.square(44),
          shape: const CircleBorder(),
        ),
      ),
      child: _PurchaseLogRows(
        month: month,
        onArchivePurchase: onArchivePurchase,
        onViewPurchase: onViewPurchase,
        onViewReceipt: onViewReceipt,
      ),
    );
  }
}

class _PurchaseLogRows extends StatefulWidget {
  const _PurchaseLogRows({
    required this.month,
    required this.onArchivePurchase,
    required this.onViewPurchase,
    required this.onViewReceipt,
  });

  final FinanceMonth month;
  final ValueChanged<PurchaseEntry> onArchivePurchase;
  final void Function(PurchaseEntry purchase, double balanceAfter)
  onViewPurchase;
  final ValueChanged<PurchaseEntry> onViewReceipt;

  @override
  State<_PurchaseLogRows> createState() => _PurchaseLogRowsState();
}

class _PurchaseLogRowsState extends State<_PurchaseLogRows> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _PurchaseLogRows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month.activePurchases.length !=
        widget.month.activePurchases.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        child: SizedBox(
          width: _purchaseTableWidth,
          child: Column(
            children: [
              const _PurchaseTableHeader(),
              for (
                var index = 0;
                index < widget.month.activePurchases.length;
                index++
              )
                Builder(
                  builder: (context) {
                    final purchase = widget.month.activePurchases[index];
                    final balanceAfter = widget.month.runningBalanceAfter(
                      purchase,
                    );
                    return _PurchaseTableRow(
                      purchase: purchase,
                      accountColor: widget.month.accounts
                          .firstWhere(
                            (account) => account.name == purchase.account,
                          )
                          .color,
                      balanceAfter: balanceAfter,
                      isLast: index == widget.month.activePurchases.length - 1,
                      onTap: () =>
                          widget.onViewPurchase(purchase, balanceAfter),
                      onArchive: () => widget.onArchivePurchase(purchase),
                      onViewReceipt: () => widget.onViewReceipt(purchase),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseTableHeader extends StatelessWidget {
  const _PurchaseTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
      decoration: const BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _purchaseDateWidth,
            child: Center(child: _TableHeader('Date')),
          ),
          SizedBox(width: 10),
          SizedBox(width: _purchaseItemWidth, child: _TableHeader('Item')),
          SizedBox(width: 10),
          SizedBox(
            width: _purchaseCategoryWidth,
            child: _TableHeader('Category'),
          ),
          SizedBox(width: 10),
          SizedBox(width: _purchaseAmountWidth, child: _TableHeader('Amount')),
          SizedBox(width: 10),
          SizedBox(width: _purchaseBankWidth, child: _TableHeader('Paid With')),
          SizedBox(width: 10),
          SizedBox(
            width: _purchaseBalanceWidth,
            child: _TableHeader('Balance'),
          ),
          SizedBox(width: 10),
          SizedBox(width: _purchaseNotesWidth, child: _TableHeader('Notes')),
          SizedBox(width: _purchaseActionWidth),
        ],
      ),
    );
  }
}

class _PurchaseTableRow extends StatelessWidget {
  const _PurchaseTableRow({
    required this.purchase,
    required this.accountColor,
    required this.balanceAfter,
    required this.isLast,
    required this.onTap,
    required this.onArchive,
    required this.onViewReceipt,
  });

  final PurchaseEntry purchase;
  final Color accountColor;
  final double balanceAfter;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onViewReceipt;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 82,
          padding: const EdgeInsets.fromLTRB(0, 10, 8, 10),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: _purchaseDateWidth,
                child: Center(child: _DatePill(date: purchase.date)),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: _purchaseItemWidth,
                child: _DescriptionCell(purchase: purchase),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: _purchaseCategoryWidth,
                child: _CategoryPill(category: purchase.category),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: _purchaseAmountWidth,
                child: _MoneyCell(amount: purchase.amount, emphasized: true),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: _purchaseBankWidth,
                child: _BankPill(
                  accountName: purchase.account,
                  color: accountColor,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: _purchaseBalanceWidth,
                child: Text(
                  formatCurrency(context, balanceAfter),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: _purchaseNotesWidth,
                child: _PurchaseNotesCell(
                  purchase: purchase,
                  onViewReceipt: onViewReceipt,
                ),
              ),
              SizedBox(
                width: _purchaseActionWidth,
                child: IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  onPressed: onArchive,
                  icon: const Icon(Icons.archive_rounded, size: 18),
                  tooltip: 'Archive Purchase',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FinanceAnalytics extends StatelessWidget {
  const FinanceAnalytics({
    required this.month,
    required this.allMonths,
    super.key,
  });

  final FinanceMonth month;
  final Map<int, FinanceMonth> allMonths;

  @override
  Widget build(BuildContext context) {
    final categorySpending = month.spendingByCategory;
    final accountSpending = month.spendingByAccount;

    return _Panel(
      title: 'Money Snapshot',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _AnalyticsMetricCard(
                  title: 'Spent',
                  amount: month.totalSpent,
                  detail: '${month.activePurchases.length} purchases',
                  icon: Icons.shopping_bag_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AnalyticsMetricCard(
                  title: 'Left',
                  amount: month.currentBalance,
                  detail:
                      '${month.savingsRate.clamp(0, 100).toStringAsFixed(0)}% of start',
                  icon: Icons.savings_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InsightPanel(
            title: 'Where Your Money Went',
            child: SizedBox(
              height: 210,
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CustomPaint(
                          painter: _DonutPainter(categorySpending),
                          child: Center(
                            child: _ChartCenterLabel(
                              title: 'Total Spent',
                              amount: month.totalSpent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BreakdownList(
                      values: categorySpending,
                      total: month.totalSpent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _InsightPanel(
            title: 'Which Bank Paid',
            child: _BreakdownList(
              values: accountSpending,
              total: month.totalSpent,
              emptyMessage: 'No bank spending yet.',
            ),
          ),
          const SizedBox(height: 12),
          _InsightPanel(
            title: 'Biggest Purchases',
            child: _TopExpenseList(purchases: month.topExpenses),
          ),
          const SizedBox(height: 12),
          _InsightPanel(
            title: 'Monthly View',
            child: SizedBox(
              height: 150,
              child: CustomPaint(
                painter: _MonthlyBarsPainter(allMonths),
                child: const Align(
                  alignment: Alignment.topRight,
                  child: _ChartLegend(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsMetricCard extends StatelessWidget {
  const _AnalyticsMetricCard({
    required this.title,
    required this.amount,
    required this.detail,
    required this.icon,
  });

  final String title;
  final double amount;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 128),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
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
          Icon(icon, color: AppColors.blue, size: 22),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatCurrency(context, amount),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({required this.title, required this.child});

  final String title;
  final Widget child;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ChartCenterLabel extends StatelessWidget {
  const _ChartCenterLabel({required this.title, required this.amount});

  final String title;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          formatCurrency(context, amount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.muted,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.date});

  final DateTime date;

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
        _shortDate(date),
        style: const TextStyle(
          color: AppColors.softText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DescriptionCell extends StatelessWidget {
  const _DescriptionCell({required this.purchase});

  final PurchaseEntry purchase;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 170),
      child: Text(
        purchase.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.activeCard,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.softText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MoneyCell extends StatelessWidget {
  const _MoneyCell({required this.amount, this.emphasized = false});

  final double amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        formatCurrency(context, amount),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: emphasized ? AppColors.blue : AppColors.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BankPill extends StatelessWidget {
  const _BankPill({required this.accountName, this.color = AppColors.primary});

  final String accountName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        accountName,
        style: const TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PurchaseNotesCell extends StatelessWidget {
  const _PurchaseNotesCell({
    required this.purchase,
    required this.onViewReceipt,
  });

  final PurchaseEntry purchase;
  final VoidCallback onViewReceipt;

  @override
  Widget build(BuildContext context) {
    final note = purchase.notes.isEmpty ? 'No notes' : purchase.notes;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          note,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.softText,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (purchase.hasReceipt) ...[
          const SizedBox(height: 4),
          InkWell(
            onTap: onViewReceipt,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.image_rounded,
                  size: 16,
                  color: AppColors.blue,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    purchase.receiptName ?? 'Receipt',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing});

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

class _BigMoneyCard extends StatelessWidget {
  const _BigMoneyCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  final String title;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
          Text(
            title,
            maxLines: 2,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(context, amount, decimalDigits: 0),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  const _MoneyLine({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatCurrency(context, amount),
            textAlign: TextAlign.right,
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

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.budget,
    required this.spent,
    required this.onTap,
  });

  final CategoryBudget budget;
  final double spent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = budget.monthlyBudget <= 0
        ? 1.0
        : spent / budget.monthlyBudget;
    final status = ratio >= 1
        ? '⚠ Over budget'
        : ratio >= .8
        ? '⚡ Near limit'
        : '✓ On track';

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(
        budget.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: LinearProgressIndicator(
        value: ratio.clamp(0, 1),
        color: ratio >= 1
            ? AppColors.blue
            : ratio >= .8
            ? AppColors.violet
            : AppColors.primary,
        backgroundColor: AppColors.chip,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${formatCurrency(context, spent, decimalDigits: 0)} / ${formatCurrency(context, budget.monthlyBudget, decimalDigits: 0)}',
          ),
          Text(status, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _BreakdownList extends StatelessWidget {
  const _BreakdownList({
    required this.values,
    required this.total,
    this.emptyMessage = 'No spending yet.',
  });

  final Map<String, double> values;
  final double total;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final nonZero = values.entries.where((entry) => entry.value > 0).toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    if (nonZero.isEmpty) {
      return Text(
        emptyMessage,
        style: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      children: [
        for (final entry in nonZero.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BreakdownRow(
              label: entry.key,
              amount: entry.value,
              percent: total <= 0 ? 0 : entry.value / total,
            ),
          ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.amount,
    required this.percent,
  });

  final String label;
  final double amount;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              formatCurrency(context, amount),
              style: const TextStyle(
                color: AppColors.softText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent.clamp(0, 1),
          minHeight: 8,
          borderRadius: BorderRadius.circular(999),
          backgroundColor: AppColors.chip,
          color: AppColors.blue,
        ),
        const SizedBox(height: 4),
        Text(
          '${(percent * 100).toStringAsFixed(0)}% of spending',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TopExpenseList extends StatelessWidget {
  const _TopExpenseList({required this.purchases});

  final List<PurchaseEntry> purchases;

  @override
  Widget build(BuildContext context) {
    if (purchases.isEmpty) {
      return const Text(
        'No purchases yet.',
        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
      );
    }

    return Column(
      children: [
        for (final purchase in purchases)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    purchase.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                _CategoryPill(category: purchase.category),
                const SizedBox(width: 10),
                Text(
                  formatCurrency(context, purchase.amount),
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: const [
        _LegendItem(color: AppColors.blue, label: 'Starting Money'),
        _LegendItem(color: AppColors.primary, label: 'Spent'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.values);

  final Map<String, double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.values.fold<double>(0, (sum, value) => sum + value);
    final rect = Offset.zero & size;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;
    if (total <= 0) {
      canvas.drawArc(
        rect.deflate(28),
        0,
        math.pi * 2,
        false,
        stroke..color = AppColors.chip,
      );
      return;
    }

    var start = -math.pi / 2;
    final colors = [
      AppColors.primary,
      AppColors.violet,
      AppColors.blue,
      AppColors.lilac,
      AppColors.activeCard,
      AppColors.line,
    ];
    var index = 0;
    for (final value in values.values.where((value) => value > 0)) {
      final sweep = (value / total) * math.pi * 2;
      canvas.drawArc(
        rect.deflate(28),
        start,
        sweep,
        false,
        stroke..color = colors[index % colors.length],
      );
      start += sweep;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _MonthlyBarsPainter extends CustomPainter {
  _MonthlyBarsPainter(this.months);

  final Map<int, FinanceMonth> months;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = months.values.fold<double>(
      1,
      (max, month) =>
          math.max(max, math.max(month.initialBalance, month.totalSpent)),
    );
    final barWidth = size.width / 12;
    final paint = Paint();
    for (var month = 1; month <= 12; month++) {
      final data = months[month]!;
      final x = (month - 1) * barWidth + 4;
      final initialHeight =
          (data.initialBalance / maxValue) * (size.height - 24);
      final spentHeight = (data.totalSpent / maxValue) * (size.height - 24);
      paint.color = AppColors.blue.withValues(alpha: .7);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x,
            size.height - initialHeight,
            barWidth / 3,
            initialHeight,
          ),
          const Radius.circular(4),
        ),
        paint,
      );
      paint.color = AppColors.primary;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x + barWidth / 3 + 3,
            size.height - spentHeight,
            barWidth / 3,
            spentHeight,
          ),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyBarsPainter oldDelegate) {
    return oldDelegate.months != months;
  }
}

String _shortDate(DateTime date) {
  return '${date.month}/${date.day}';
}
