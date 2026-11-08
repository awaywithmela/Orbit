import 'dart:typed_data';

import 'package:flutter/material.dart';

class BankAccount {
  const BankAccount({
    required this.name,
    required this.initialBalance,
    required this.color,
    this.id,
  });

  final String? id;
  final String name;
  final double initialBalance;
  final Color color;

  BankAccount copyWith({double? initialBalance}) {
    return BankAccount(
      name: name,
      initialBalance: initialBalance ?? this.initialBalance,
      color: color,
      id: id,
    );
  }
}

class CategoryBudget {
  const CategoryBudget({
    required this.name,
    required this.monthlyBudget,
    this.id,
    this.categoryId,
  });

  final String? id;
  final String? categoryId;
  final String name;
  final double monthlyBudget;

  CategoryBudget copyWith({double? monthlyBudget}) {
    return CategoryBudget(
      name: name,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      id: id,
      categoryId: categoryId,
    );
  }
}

class PurchaseEntry {
  const PurchaseEntry({
    required this.date,
    required this.description,
    required this.category,
    required this.amount,
    required this.account,
    required this.notes,
    this.receiptPath,
    this.receiptName,
    this.receiptBytes,
    this.archived = false,
    this.id,
    this.accountId,
    this.categoryId,
  });

  final String? id;
  final String? accountId;
  final String? categoryId;
  final DateTime date;
  final String description;
  final String category;
  final double amount;
  final String account;
  final String notes;
  final String? receiptPath;
  final String? receiptName;
  final Uint8List? receiptBytes;
  final bool archived;

  bool get hasReceipt {
    return receiptBytes != null ||
        (receiptPath != null && receiptPath!.isNotEmpty);
  }

  PurchaseEntry copyWith({bool? archived}) {
    return PurchaseEntry(
      date: date,
      description: description,
      category: category,
      amount: amount,
      account: account,
      notes: notes,
      receiptPath: receiptPath,
      receiptName: receiptName,
      receiptBytes: receiptBytes,
      archived: archived ?? this.archived,
      id: id,
      accountId: accountId,
      categoryId: categoryId,
    );
  }
}

class FinanceMonth {
  const FinanceMonth({
    required this.accounts,
    required this.categoryBudgets,
    required this.purchases,
  });

  final List<BankAccount> accounts;
  final List<CategoryBudget> categoryBudgets;
  final List<PurchaseEntry> purchases;

  List<PurchaseEntry> get activePurchases {
    return purchases.where((purchase) => !purchase.archived).toList();
  }

  double get initialBalance {
    return accounts.fold<double>(
      0,
      (sum, account) => sum + account.initialBalance,
    );
  }

  double get totalSpent {
    return activePurchases.fold<double>(0, (sum, entry) => sum + entry.amount);
  }

  double get totalWealth {
    return accounts.fold<double>(
      0,
      (sum, account) => sum + accountBalance(account.name),
    );
  }

  double get currentBalance => totalWealth;

  double get savingsRate {
    if (initialBalance <= 0) {
      return 0;
    }
    return (currentBalance / initialBalance) * 100;
  }

  Map<String, double> get spendingByAccount {
    final totals = {for (final account in accounts) account.name: 0.0};
    for (final purchase in activePurchases) {
      totals[purchase.account] =
          (totals[purchase.account] ?? 0) + purchase.amount;
    }
    return totals;
  }

  Map<String, double> get spendingByCategory {
    final totals = {for (final budget in categoryBudgets) budget.name: 0.0};
    for (final purchase in activePurchases) {
      totals[purchase.category] =
          (totals[purchase.category] ?? 0) + purchase.amount;
    }
    return totals;
  }

  double accountSpent(String accountName) {
    return purchases
        .where(
          (purchase) => !purchase.archived && purchase.account == accountName,
        )
        .fold<double>(0, (sum, purchase) => sum + purchase.amount);
  }

  double accountBalance(String accountName) {
    final account = accounts.firstWhere((entry) => entry.name == accountName);
    return account.initialBalance - accountSpent(accountName);
  }

  double runningBalanceAfter(PurchaseEntry target) {
    final account = accounts.firstWhere(
      (entry) => entry.name == target.account,
    );
    var balance = account.initialBalance;
    for (final purchase in activePurchases) {
      if (purchase.account == target.account) {
        balance -= purchase.amount;
      }
      if (identical(purchase, target)) {
        return balance;
      }
    }
    return balance;
  }

  List<PurchaseEntry> get topExpenses {
    final sorted = [...activePurchases]
      ..sort((left, right) => right.amount.compareTo(left.amount));
    return sorted.take(5).toList();
  }

  FinanceMonth copyWith({
    List<BankAccount>? accounts,
    List<CategoryBudget>? categoryBudgets,
    List<PurchaseEntry>? purchases,
  }) {
    return FinanceMonth(
      accounts: accounts ?? this.accounts,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      purchases: purchases ?? this.purchases,
    );
  }
}
