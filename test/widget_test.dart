import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orbit/main.dart';
import 'package:orbit/core/theme/app_theme.dart';
import 'package:orbit/shared/widgets/rounded_dropdown_form_field.dart';
import 'package:orbit/features/orbit/presentation/widgets/dialogs.dart';
import 'package:orbit/features/orbit/presentation/orbit_home_page.dart';
import 'package:orbit/core/formatting/currency_format.dart';

void main() {
  test('all registration currencies have the correct display symbol', () {
    expect(currencySymbolFor('PHP'), '₱');
    expect(currencySymbolFor('USD'), r'$');
    expect(currencySymbolFor('EUR'), '€');
    expect(currencySymbolFor('GBP'), '£');
    expect(currencySymbolFor('CAD'), r'CA$');
    expect(currencySymbolFor('AUD'), r'A$');
    expect(currencySymbolFor('JPY'), '¥');
    expect(currencySymbolFor('SGD'), r'S$');
    expect(currencySymbolFor('AED'), 'د.إ ');
    expect(currencySymbolFor('INR'), '₹');
    expect(currencySymbolFor('KRW'), '₩');
    expect(currencySymbolFor('CHF'), 'CHF ');
    expect(currencySymbolFor('NZD'), 'NZD ');
  });

  testWidgets('authentication uses local credentials', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OrbitApp());

    await tester.tap(find.text('Skip'));
    await tester.pump();

    expect(find.text('Guest'), findsNothing);
    expect(find.text('Create Account'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('continueToOrbitButton')));
    await tester.pumpAndSettle();

    expect(
      find.text('Please add your name to create an account.'),
      findsOneWidget,
    );
    expect(find.text('Your day, sorted into doable moments.'), findsNothing);

    await tester.tap(find.text('Log In').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profileEmailField')),
      'person@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('continueToOrbitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your password.'), findsOneWidget);
    expect(find.text('Your day, sorted into doable moments.'), findsNothing);
  });

  testWidgets('signup only shows the centered currency dropdown', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OrbitApp());

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Main Support Needed'), findsNothing);
    expect(find.text('Reminder Style'), findsNothing);
    expect(find.text('Default Currency'), findsOneWidget);
    expect(find.byType(RoundedDropdownFormField<String>), findsOneWidget);

    final dropdown = tester.widget<RoundedDropdownFormField<String>>(
      find.byType(RoundedDropdownFormField<String>),
    );
    expect(dropdown.menuMaxHeight, 280);
    expect(dropdown.itemHeight, 56);
    expect(dropdown.items, isNotEmpty);

    await tester.ensureVisible(
      find.byKey(const ValueKey('roundedDropdownButton')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('roundedDropdownButton')));
    await tester.pumpAndSettle();
    expect(
      find.byType(PopupMenuItem<String>),
      findsNWidgets(dropdown.items.length),
    );
    expect(find.text('PHP - Peso'), findsWidgets);
  });

  testWidgets('password can be shown and hidden', (WidgetTester tester) async {
    await tester.pumpWidget(const OrbitApp());
    await tester.tap(find.text('Skip'));
    await tester.pump();

    TextField passwordField = tester.widget(
      find.byKey(const ValueKey('profilePasswordField')),
    );
    expect(passwordField.obscureText, isTrue);

    await tester.tap(find.byKey(const ValueKey('togglePasswordVisibility')));
    await tester.pump();
    passwordField = tester.widget(
      find.byKey(const ValueKey('profilePasswordField')),
    );
    expect(passwordField.obscureText, isFalse);
  });

  testWidgets('signup requires matching password confirmation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OrbitApp());
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Password'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('profileNameField')),
      'Test User',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profileEmailField')),
      'test@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profilePasswordField')),
      'OrbitTest123!',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profileConfirmPasswordField')),
      'Different123!',
    );
    await tester.tap(find.byKey(const ValueKey('continueToOrbitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('signup requires a password of at least eight characters', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OrbitApp());
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('profileNameField')),
      'Test User',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profileEmailField')),
      'test@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profilePasswordField')),
      'short',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profileConfirmPasswordField')),
      'short',
    );
    await tester.tap(find.byKey(const ValueKey('continueToOrbitButton')));
    await tester.pumpAndSettle();

    expect(
      find.text('Use at least 8 characters for your password.'),
      findsOneWidget,
    );
  });

  testWidgets('new expense category dialog validates and returns a category', (
    WidgetTester tester,
  ) async {
    ExpenseCategoryDraft? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await showAddExpenseCategoryDialog(context);
              },
              child: const Text('Open Category'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Category'));
    await tester.pumpAndSettle();
    expect(find.text('Create Category'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('saveExpenseCategoryButton')));
    await tester.pump();
    expect(find.text('Enter a category name.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('expenseCategoryNameField')),
      'Pet Care',
    );
    await tester.enterText(
      find.byKey(const ValueKey('expenseCategoryBudgetField')),
      '1,500',
    );
    await tester.tap(find.byKey(const ValueKey('saveExpenseCategoryButton')));
    await tester.pumpAndSettle();

    expect(result?.name, 'Pet Care');
    expect(result?.monthlyBudget, 1500);
  });

  testWidgets('OrbitHomePage renders all tabs and dialogs without crashing', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const OrbitHomePage()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 'Plan' tab
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();

    expect(find.text('Build a day that has room to breathe.'), findsOneWidget);

    // Drag up to reveal bottom cards
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    final show3Finder = find.text('Show 3');
    if (show3Finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(show3Finder);
      await tester.pumpAndSettle();
      await tester.tap(show3Finder);
      await tester.pumpAndSettle();

      if (find.text('Close').evaluate().isNotEmpty) {
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
    }

    // Tap 'Expense' tab
    await tester.tap(find.text('Expense'));
    await tester.pumpAndSettle();

    // Tap 'Fitness' tab
    await tester.tap(find.text('Fitness'));
    await tester.pumpAndSettle();

    // Tap 'Me' tab
    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
