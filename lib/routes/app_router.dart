import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense_item.dart';
import '../screens/dashboard_screen.dart';
import '../screens/scanner_screen.dart';
import '../screens/review_receipt_screen.dart';
import '../screens/expense_detail_screen.dart';
import '../services/receipt_parser.dart';

// ─── Route Names (type-safe constants) ───────────────────────────────────────

class AppRoutes {
  AppRoutes._();
  static const String dashboard = '/dashboard';
  static const String scanner = '/scanner';
  static const String review = '/review';
  static const String expenseDetail = '/expense/:id';
}

// ─── Bottom Navigation Shell ──────────────────────────────────────────────────

/// Persistent bottom navigation shell using GoRouter's ShellRoute
class _AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _AppShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        backgroundColor: colorScheme.surface,
        indicatorColor: const Color(0xFF2C4570).withOpacity(0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner_rounded),
            label: 'Quét hóa đơn',
          ),
        ],
      ),
    );
  }
}

// ─── Router Configuration ─────────────────────────────────────────────────────

/// Global GoRouter instance for declarative, type-safe navigation.
///
/// Structure:
/// - ShellRoute (persistent bottom nav)
///   - /dashboard → DashboardScreen
///   - /scanner → ScannerScreen
/// - /review → ReviewReceiptScreen (receives ParsedReceipt as extra)
/// - /expense/:id → ExpenseDetailScreen
final appRouter = GoRouter(
  initialLocation: AppRoutes.dashboard,
  debugLogDiagnostics: false,
  routes: [
    // ── Shell with persistent bottom navigation ──────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _AppShell(navigationShell: navigationShell),
      branches: [
        // Branch 0: Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              name: 'dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        // Branch 1: Scanner
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.scanner,
              name: 'scanner',
              builder: (context, state) => const ScannerScreen(),
            ),
          ],
        ),
      ],
    ),

    // ── Review Screen — receives ParsedReceipt via router 'extra' ─────────────
    GoRoute(
      path: AppRoutes.review,
      name: 'review',
      builder: (context, state) {
        final parsed = state.extra as ParsedReceipt?;
        return ReviewReceiptScreen(parsedReceipt: parsed);
      },
    ),

    // ── Expense Detail Screen ─────────────────────────────────────────────────
    GoRoute(
      path: '/expense/:id',
      name: 'expenseDetail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final expense = state.extra as ExpenseItem?;
        return ExpenseDetailScreen(expenseId: id, expense: expense);
      },
    ),
  ],

  // ── Error Page ────────────────────────────────────────────────────────────
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy trang',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(state.error?.message ?? 'Đã xảy ra lỗi không xác định'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go(AppRoutes.dashboard),
            child: const Text('Về trang chủ'),
          ),
        ],
      ),
    ),
  ),
);

/// Riverpod provider for the GoRouter instance
final appRouterProvider = Provider<GoRouter>((ref) => appRouter);
