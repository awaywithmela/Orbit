import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/theme/app_theme.dart';
import 'package:orbit/features/auth/application/auth_controller.dart';
import 'package:orbit/features/auth/application/auth_state.dart';
import 'package:orbit/features/auth/domain/user_profile.dart';
import 'package:orbit/features/help/presentation/orbit_help.dart';
import 'package:orbit/features/orbit/application/orbit_controller.dart';
import 'package:orbit/features/orbit/domain/app_tab.dart';
import 'package:orbit/features/orbit/presentation/widgets/page_header.dart';
import 'package:orbit/features/orbit/presentation/widgets/today_widgets.dart';

class MemoryGuideStorage extends GuideStorage {
  final seen = <String>{};
  @override
  Future<bool> hasSeen(String key) async => seen.contains(key);
  @override
  Future<void> markSeen(String key) async {
    seen.add(key);
  }
}

class HelpTestAuth extends AuthController {
  @override
  AuthState build() => const AuthState(
    profile: UserProfile(
      id: 'test-user',
      displayName: 'Test',
      email: 'test@example.com',
      currencyCode: 'PHP',
    ),
    isLoading: false,
    errorMessage: null,
  );
}

void main() {
  testWidgets('headers keep About reachable with larger system text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final header in <Widget>[
      const PageHeader(
        title: 'Profile & Settings',
        subtitle: 'Manage your account and saved data.',
        icon: Icons.person_outline,
      ),
      HomeHeader(onAddTaskTap: () {}, onRemindersTap: () {}),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Padding(padding: const EdgeInsets.all(22), child: header),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final about = find.byTooltip('About Orbit');
      expect(about, findsOneWidget);
      expect(MediaQuery.textScalerOf(tester.element(about)).scale(14), 28);
      await tester.tap(about);
      await tester.pumpAndSettle();
      expect(find.byType(OrbitAboutPage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('first-visit dismissal persists and keeps help available', (
    tester,
  ) async {
    final storage = MemoryGuideStorage();
    Widget app(Key key) => ProviderScope(
      overrides: [
        guideStorageProvider.overrideWithValue(storage),
        authControllerProvider.overrideWith(HelpTestAuth.new),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: FirstVisitGuide(key: key, tab: AppTab.today),
        ),
      ),
    );
    await tester.pumpWidget(app(const ValueKey('first')));
    await tester.pumpAndSettle();
    expect(find.text('New here? Start small.'), findsOneWidget);
    await tester.tap(find.byTooltip('Dismiss introduction'));
    await tester.pumpAndSettle();
    expect(storage.seen, contains('help.v1.test-user.today'));
    await tester.pumpWidget(app(const ValueKey('return')));
    await tester.pumpAndSettle();
    expect(find.text('New here? Start small.'), findsNothing);
    await tester.tap(find.text('Quick guide'));
    await tester.pumpAndSettle();
    expect(find.text('Today & focus'), findsOneWidget);
    expect(find.text('Brain dump & resets'), findsOneWidget);
    expect(find.text('Wallets & expenses'), findsNothing);
  });

  testWidgets(
    'every guide advances one step at a time and supports going back',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final guide in featureGuides) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              key: ValueKey(guide.title),
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: FeatureGuidePage(guide: guide),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (var step = 0; step < guide.steps.length - 1; step++) {
          expect(find.text(guide.steps[step].$1), findsOneWidget);
          await tester.ensureVisible(find.text('Next step'));
          await tester.tap(find.text('Next step'));
          await tester.pumpAndSettle();
        }
        expect(find.text(guide.steps.last.$1), findsOneWidget);
        await tester.ensureVisible(find.text('Previous step'));
        await tester.tap(find.text('Previous step'));
        await tester.pumpAndSettle();
        expect(
          find.text(guide.steps[guide.steps.length - 2].$1),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: guide.title);
      }
    },
  );

  testWidgets('About links to guides and Try it opens the correct tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Column(children: [OrbitAboutButton(), OrbitHelpLinks()]),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('About Orbit'));
    await tester.pumpAndSettle();
    expect(find.text('Developed by Nova'), findsOneWidget);
    await tester.tap(find.text('Your data & privacy'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('saved in a local database on this device'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('How to use Orbit'));
    await tester.tap(find.text('How to use Orbit'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Wallets & expenses'), 200);
    await tester.tap(find.text('Wallets & expenses'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next step'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Try it in Expense'));
    await tester.pumpAndSettle();
    expect(find.byType(OrbitHelpLinks), findsOneWidget);
    expect(find.byType(OrbitAboutPage), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(OrbitHelpLinks)),
    );
    expect(
      container.read(orbitControllerProvider).selectedTab,
      AppTab.expenses,
    );
  });
}
