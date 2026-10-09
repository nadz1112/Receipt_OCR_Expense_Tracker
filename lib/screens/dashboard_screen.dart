import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_router.dart';
import '../state/expense_provider.dart';
import '../widgets/expense_summary_card.dart';
import '../widgets/charts/chart_painters.dart';
import '../core/utils/format_utils.dart';

/// Dashboard Screen — main overview of expenses, charts, and spending stats.
///
/// Uses [ConsumerWidget] for reactive Riverpod state updates.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseNotifierProvider);
    final categoryBreakdown = ref.watch(categoryBreakdownProvider);
    final weeklyTotals = ref.watch(weeklyTotalsProvider);
    final monthlyTotal = ref.watch(monthlyTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VKU Quản Lý Chi Tiêu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Thêm chi tiêu thủ công',
            onPressed: () => context.push(AppRoutes.review),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Summary Header ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SummaryHeader(monthlyTotal: monthlyTotal),
          ),

          // ── Charts Section ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ChartsSection(
              categoryBreakdown: categoryBreakdown,
              weeklyTotals: weeklyTotals,
            ),
          ),

          // ── Section Header ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'Chi tiêu gần đây',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),

          // ── Expense List ──────────────────────────────────────────────
          if (expenses.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final expense = expenses[index];
                  return ExpenseSummaryCard(
                    merchant: expense.merchant,
                    amount: expense.amount,
                    date: expense.timestamp,
                    category: expense.category,
                    onTap: () => context.push(
                      '/expense/${expense.id}',
                      extra: expense,
                    ),
                  );
                },
                childCount: expenses.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

/// Monthly spending summary header card
class _SummaryHeader extends StatelessWidget {
  final double monthlyTotal;

  const _SummaryHeader({required this.monthlyTotal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C4570), Color(0xFF4A6FA5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C4570).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tháng này',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            FormatUtils.formatVND(monthlyTotal),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tổng chi tiêu trong tháng',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Charts section containing donut and bar chart
class _ChartsSection extends StatelessWidget {
  final Map<String, double> categoryBreakdown;
  final List<double> weeklyTotals;

  const _ChartsSection({
    required this.categoryBreakdown,
    required this.weeklyTotals,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Donut Chart ─────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phân loại theo danh mục',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: DonutChart(
                      categoryBreakdown: categoryBreakdown,
                      size: 180,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Weekly Bar Chart ─────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chi tiêu tuần này',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  WeeklyBarChart(weeklyTotals: weeklyTotals),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state for no expenses
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có khoản chi tiêu nào',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade400,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chuyển sang tab Quét hóa đơn để ghi lại chi tiêu đầu tiên',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
