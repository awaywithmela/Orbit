import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/formatting/currency_format.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/auth_gate.dart';

class OrbitApp extends StatelessWidget {
  const OrbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Orbit',
        theme: AppTheme.light,
        // Keep currency above the Navigator so dialogs and sheets inherit it.
        builder: (context, child) => Consumer(
          builder: (context, ref, _) => CurrencyScope(
            currencyCode: ref.watch(
              authControllerProvider.select(
                (state) => state.profile?.currencyCode ?? 'PHP',
              ),
            ),
            child: child!,
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}
