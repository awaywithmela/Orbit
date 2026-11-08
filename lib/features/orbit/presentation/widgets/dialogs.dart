import 'package:flutter/material.dart';

import '../../../../core/formatting/currency_format.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/rounded_dropdown_form_field.dart';
import '../../domain/finance_models.dart';
import '../../domain/schedule_block.dart';

Future<BankAccount?> showAddAccountDialog(BuildContext context) {
  final nameController = TextEditingController();
  final balanceController = TextEditingController();
  var selectedColor = AppColors.pastelSky;
  const colorOptions = [
    AppColors.pastelSky,
    AppColors.pastelBlue,
    AppColors.pastelMint,
    AppColors.pastelGreen,
    AppColors.pastelLavender,
    AppColors.pastelPurple,
    AppColors.pastelPink,
    AppColors.pastelMagenta,
    AppColors.pastelPeach,
    AppColors.pastelOrange,
    AppColors.pastelLemon,
    AppColors.pastelCream,
    AppColors.pastelAqua,
    AppColors.pastelTeal,
    AppColors.pastelRose,
    AppColors.pastelCoral,
    AppColors.pastelSlate,
    AppColors.pastelGray,
  ];

  return showDialog<BankAccount>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.panel,
            title: const Text('Add Bank / Wallet'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Bank / Wallet Name',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: balanceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Initial Balance',
                      prefixText: '${currencySymbolOf(context)} ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bank Color',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      for (final color in colorOptions)
                        InkWell(
                          onTap: () =>
                              setDialogState(() => selectedColor = color),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadow.withValues(
                                    alpha: 0.18,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(
                                color: selectedColor == color
                                    ? AppColors.text
                                    : AppColors.border,
                                width: selectedColor == color ? 3 : 1.4,
                              ),
                            ),
                            child: selectedColor == color
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.text,
                                    size: 20,
                                  )
                                : null,
                          ),
                        ),
                    ],
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
                  final balance =
                      double.tryParse(balanceController.text.trim()) ?? 0;
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add an account name.')),
                    );
                    return;
                  }
                  Navigator.pop(
                    context,
                    BankAccount(
                      name: name,
                      initialBalance: balance,
                      color: selectedColor,
                    ),
                  );
                },
                child: const Text('Add Account'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<ScheduleBlock?> showAddTaskDialog(BuildContext context) {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final detailsController = TextEditingController();
  final timeController = TextEditingController(text: '2:00');
  final durationHoursController = TextEditingController(text: '0');
  final durationMinutesController = TextEditingController(text: '25');

  return showDialog<ScheduleBlock>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Add To Today Timeline'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                  hintText: 'Example: Pay electricity bill',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Short Description',
                  hintText: 'What is this task about?',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: detailsController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Details / Tiny Steps',
                  hintText: 'First step, notes, links, reminders...',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: timeController,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        hintText: '2:00',
                        helperText: 'When it starts',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: durationHoursController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Hours',
                        suffixText: 'hr',
                        helperText: '0, 1, 2...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: durationMinutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        suffixText: 'min',
                        helperText: '0-59',
                      ),
                    ),
                  ),
                ],
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task needs a name first.')),
                );
                return;
              }
              final duration = _formatDurationLabel(
                durationHoursController.text,
                durationMinutesController.text,
              );

              Navigator.pop(
                context,
                ScheduleBlock(
                  time: timeController.text.trim().isEmpty
                      ? 'Later'
                      : timeController.text.trim(),
                  title: title,
                  description: descriptionController.text.trim().isEmpty
                      ? 'No description yet'
                      : descriptionController.text.trim(),
                  details: detailsController.text.trim().isEmpty
                      ? 'Break this into one tiny first step.'
                      : detailsController.text.trim(),
                  duration: duration,
                  icon: Icons.task_alt_rounded,
                  color: AppColors.violet,
                ),
              );
            },
            child: const Text('Add To Timeline'),
          ),
        ],
      );
    },
  );
}

String _formatDurationLabel(String hoursText, String minutesText) {
  final hours = int.tryParse(hoursText.trim()) ?? 0;
  final minutes = int.tryParse(minutesText.trim()) ?? 0;
  final safeHours = hours < 0 ? 0 : hours;
  final safeMinutes = minutes < 0 ? 0 : minutes;
  final totalMinutes = (safeHours * 60) + safeMinutes;

  if (totalMinutes <= 0) {
    return '25m';
  }

  final displayHours = totalMinutes ~/ 60;
  final displayMinutes = totalMinutes % 60;
  if (displayHours > 0 && displayMinutes > 0) {
    return '${displayHours}h ${displayMinutes}m';
  }
  if (displayHours > 0) {
    return '${displayHours}h';
  }
  return '${displayMinutes}m';
}

Future<PurchaseEntry?> showAddPurchaseDialog({
  required BuildContext context,
  required List<String> categories,
  required List<String> accounts,
  String? initialAccount,
}) {
  if (categories.isEmpty || accounts.isEmpty) {
    return Future.value(null);
  }
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  final picker = ImagePicker();
  var selectedCategory = categories.first;
  var selectedAccount = accounts.contains(initialAccount)
      ? initialAccount!
      : accounts.contains('Cash')
      ? 'Cash'
      : accounts.first;
  XFile? receiptImage;

  return showDialog<PurchaseEntry>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.panel,
            title: const Text('Add Expense'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descriptionController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 10),
                  RoundedDropdownFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      for (final category in categories)
                        DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount (${CurrencyScope.codeOf(context)})',
                    ),
                  ),
                  const SizedBox(height: 10),
                  RoundedDropdownFormField<String>(
                    value: selectedAccount,
                    decoration: const InputDecoration(
                      labelText: 'Bank / Wallet',
                    ),
                    items: [
                      for (final account in accounts)
                        DropdownMenuItem(value: account, child: Text(account)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedAccount = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      if (image != null) {
                        setDialogState(() => receiptImage = image);
                      }
                    },
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: Text(
                      receiptImage == null
                          ? 'Upload Receipt Picture'
                          : 'Receipt: ${receiptImage!.name}',
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
                onPressed: () async {
                  final description = descriptionController.text.trim();
                  final amount = double.tryParse(
                    amountController.text.trim().replaceAll(',', ''),
                  );
                  if (description.isEmpty || amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Add a description and an amount greater than zero.',
                        ),
                      ),
                    );
                    return;
                  }

                  final receiptBytes = await receiptImage?.readAsBytes();
                  if (!context.mounted) {
                    return;
                  }

                  Navigator.pop(
                    context,
                    PurchaseEntry(
                      date: DateTime.now(),
                      description: description,
                      category: selectedCategory,
                      amount: amount,
                      account: selectedAccount,
                      notes: notesController.text.trim(),
                      receiptPath: receiptImage?.path,
                      receiptName: receiptImage?.name,
                      receiptBytes: receiptBytes,
                    ),
                  );
                },
                child: const Text('Save Expense'),
              ),
            ],
          );
        },
      );
    },
  );
}

class ExpenseCategoryDraft {
  const ExpenseCategoryDraft({
    required this.name,
    required this.color,
    required this.monthlyBudget,
  });

  final String name;
  final Color color;
  final double monthlyBudget;
}

Future<ExpenseCategoryDraft?> showAddExpenseCategoryDialog(
  BuildContext context,
) {
  final nameController = TextEditingController();
  final budgetController = TextEditingController();
  const colors = [
    Color(0xFFFFB86B),
    Color(0xFF74C0FC),
    Color(0xFFB197FC),
    Color(0xFFF783AC),
    Color(0xFF63E6BE),
    Color(0xFFFFD43B),
  ];
  var selectedColor = colors.first;
  String? errorText;

  return showDialog<ExpenseCategoryDraft>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: AppColors.panel,
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: selectedColor.withValues(alpha: .22),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.category_rounded, color: selectedColor),
        ),
        title: const Text('Create Category', textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Give this spending group a clear name and optional monthly budget.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                key: const ValueKey('expenseCategoryNameField'),
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Pet Care',
                  prefixIcon: const Icon(Icons.edit_rounded),
                  errorText: errorText,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('expenseCategoryBudgetField'),
                controller: budgetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Monthly Budget',
                  hintText: 'Optional',
                  prefixIcon: Icon(Icons.savings_rounded),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose a color',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final color in colors)
                    Semantics(
                      label: 'Select category color',
                      selected: selectedColor == color,
                      child: InkWell(
                        onTap: () =>
                            setDialogState(() => selectedColor = color),
                        customBorder: const CircleBorder(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor == color
                                  ? AppColors.text
                                  : Colors.white,
                              width: selectedColor == color ? 3 : 2,
                            ),
                            boxShadow: const [
                              BoxShadow(color: AppColors.shadow, blurRadius: 8),
                            ],
                          ),
                          child: selectedColor == color
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 20,
                                  color: AppColors.text,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
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
            key: const ValueKey('saveExpenseCategoryButton'),
            onPressed: () {
              final name = nameController.text.trim();
              final budgetText = budgetController.text.trim().replaceAll(
                ',',
                '',
              );
              final budget = budgetText.isEmpty
                  ? 0.0
                  : double.tryParse(budgetText);
              if (name.isEmpty) {
                setDialogState(() => errorText = 'Enter a category name.');
                return;
              }
              if (budget == null || budget < 0) {
                setDialogState(
                  () => errorText = 'Enter a valid budget or leave it blank.',
                );
                return;
              }
              Navigator.pop(
                context,
                ExpenseCategoryDraft(
                  name: name,
                  color: selectedColor,
                  monthlyBudget: budget,
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create'),
          ),
        ],
      ),
    ),
  );
}
