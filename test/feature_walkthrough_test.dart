import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/theme/app_theme.dart';
import 'package:orbit/features/auth/application/auth_controller.dart';
import 'package:orbit/features/auth/application/auth_state.dart';
import 'package:orbit/features/auth/domain/user_profile.dart';
import 'package:orbit/features/help/presentation/feature_walkthrough.dart';
import 'package:orbit/features/help/presentation/orbit_help.dart';
import 'package:orbit/features/orbit/domain/app_tab.dart';
import 'package:orbit/features/orbit/presentation/orbit_home_page.dart';

class TourTestAuth extends AuthController {
  @override
  AuthState build() => const AuthState(
    profile: UserProfile(
      id: 'tour-test',
      displayName: 'Test',
      email: 'test@example.com',
      currencyCode: 'GBP',
    ),
    isLoading: false,
    errorMessage: null,
  );
}

class SeenGuides extends GuideStorage {
  @override
  Future<bool> hasSeen(String key) async => true;
  @override
  Future<void> markSeen(String key) async {}
}

Widget app() => ProviderScope(
  overrides: [
    authControllerProvider.overrideWith(TourTestAuth.new),
    guideStorageProvider.overrideWithValue(SeenGuides()),
  ],
  child: MaterialApp(theme: AppTheme.light, home: const OrbitHomePage()),
);

void main() {
  testWidgets('every tab tour scrolls to all real controls and completes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    for (final entry in walkthroughSteps.entries) {
      final label = switch (entry.key) {
        AppTab.today => 'Today',
        AppTab.plan => 'Plan',
        AppTab.expenses => 'Expense',
        AppTab.fitness => 'Fitness',
        AppTab.me => 'Me',
      };
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quick guide'));
      await tester.pumpAndSettle();
      for (var i = 0; i < entry.value.length; i++) {
        final step = entry.value[i];
        expect(
          find.text(step.title),
          findsOneWidget,
          reason: '${entry.key}: ${step.target}',
        );
        expect(
          find.textContaining('This control is not available'),
          findsNothing,
          reason: step.target,
        );
        final target = find.byWidgetPredicate(
          (widget) => widget is TourTarget && widget.id == step.target,
        );
        expect(target, findsOneWidget);
        final rect = tester.getRect(target);
        expect(rect.top, greaterThanOrEqualTo(0), reason: step.target);
        expect(rect.bottom, lessThan(600), reason: step.target);
        await tester.tap(
          find.text(i == entry.value.length - 1 ? 'Done' : 'Next'),
        );
        await tester.pumpAndSettle();
      }
      expect(find.text('Skip tour'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('highlight opens actual control; skip and back work', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quick guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Add your first task'), findsOneWidget);
    await tester.tap(find.byTooltip('Add To Today Timeline'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Skip tour'), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quick guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip tour'));
    await tester.pumpAndSettle();
    expect(find.text('Add your first task'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
