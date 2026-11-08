import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/theme/app_theme.dart';
import 'package:orbit/features/orbit/presentation/orbit_home_page.dart';
import 'package:orbit/features/orbit/presentation/widgets/adhd_tool_card.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(900, 700)]) {
    testWidgets('reset sheet uses full width at $size with large text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: const OrbitHomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final card = find.byWidgetPredicate(
        (widget) =>
            widget is AdhdToolCard &&
            widget.title == 'Breathe And Choose One Task',
      );
      await tester.scrollUntilVisible(
        card,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      final start = find.descendant(of: card, matching: find.text('Start'));
      await tester.ensureVisible(start);
      await tester.pumpAndSettle();
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(BottomSheet)).width, size.width);
      final title = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Breathe And Choose One Task'),
      );
      expect(title, findsOneWidget);
      expect(tester.getRect(title).right, lessThanOrEqualTo(size.width - 20));
      expect(find.text('Pick one tiny next action.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
