import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/src/app.dart';
import 'package:orbit/core/formatting/currency_format.dart';
import 'package:orbit/features/auth/application/auth_controller.dart';
import 'package:orbit/features/auth/application/auth_state.dart';
import 'package:orbit/features/auth/domain/user_profile.dart';
import 'package:orbit/features/orbit/domain/finance_models.dart';
import 'package:orbit/features/orbit/presentation/widgets/expense_widgets.dart';

class CurrencyTestAuth extends AuthController {
  CurrencyTestAuth(this.currency);
  final String currency;

  @override
  AuthState build() => AuthState(
    profile: UserProfile(
      id: 'currency-test',
      displayName: 'Test',
      email: 'test@example.com',
      currencyCode: currency,
    ),
    isLoading: false,
    errorMessage: null,
  );

  void changeCurrency(String code) => state = state.copyWith(
    profile: state.profile!.copyWith(currencyCode: code),
  );
}

void main() {
  for (final code in ['GBP', 'EUR', 'USD']) {
    testWidgets(
      '$code reaches wallet and balance dialogs above the page route',
      (tester) async {
        final auth = CurrencyTestAuth(code);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authControllerProvider.overrideWith(() => auth)],
            child: const OrbitApp(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Expense'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('New Wallet'));
        await tester.pumpAndSettle();
        final walletFields = tester.widgetList<TextField>(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          ),
        );
        expect(
          walletFields.any(
            (field) =>
                field.decoration?.prefixText == '${currencySymbolFor(code)} ',
          ),
          isTrue,
        );
        expect(
          CurrencyScope.codeOf(tester.element(find.byType(AlertDialog))),
          code,
        );
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Exercise the actual balance-edit dialog without saving any data.
        tester
            .widget<AccountBalanceStrip>(find.byType(AccountBalanceStrip))
            .onEditBalance(
              const BankAccount(
                name: 'Test wallet',
                initialBalance: 0,
                color: Colors.blue,
              ),
            );
        await tester.pumpAndSettle();
        final amount = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        );
        expect(
          tester.widget<TextField>(amount).decoration?.prefixText,
          '${currencySymbolFor(code)} ',
        );
        auth.changeCurrency('JPY');
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(amount).decoration?.prefixText, '¥ ');
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
