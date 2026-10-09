import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

/// VKU Receipt OCR & Expense Tracker — Application Entry Point
///
/// Week 7: Flutter Fundamentals — Widget Tree, Material 3 Theme
/// Week 8: State Management (Riverpod 2), Routing (GoRouter), CustomPainter
void main() {
  // Ensure Flutter bindings are initialized before any async operations
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // ProviderScope is required at the root for Riverpod 2
    const ProviderScope(
      child: VkuExpenseApp(),
    ),
  );
}

/// Root application widget
class VkuExpenseApp extends ConsumerWidget {
  const VkuExpenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider for GoRouter integration
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // ── App Identity ─────────────────────────────────────────────────
      title: 'VKU Quản Lý Chi Tiêu',
      debugShowCheckedModeBanner: false,

      // ── Routing ──────────────────────────────────────────────────────
      routerConfig: router,

      // ── Themes ───────────────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}
