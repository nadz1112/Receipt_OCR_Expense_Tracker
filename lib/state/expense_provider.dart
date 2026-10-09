import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense_item.dart';
import '../services/database_helper.dart';

// ─── State Models ─────────────────────────────────────────────────────────────

/// Breakdown of spending per category
typedef CategoryBreakdown = Map<String, double>;

/// Daily totals for the current week (index 0 = Monday, 6 = Sunday)
typedef WeeklyTotals = List<double>;

// ─── Notifier ─────────────────────────────────────────────────────────────────

/// Riverpod 2 Notifier managing the global list of [ExpenseItem]s.
///
/// Provides reactive CRUD operations that sync with SQLite and automatically
/// update all listening widgets with minimal rebuilds.
class ExpenseNotifier extends Notifier<List<ExpenseItem>> {
  @override
  List<ExpenseItem> build() {
    // Kick off initial load from SQLite
    _loadExpenses();
    return [];
  }

  final DatabaseHelper _db = DatabaseHelper.instance;

  // ─── CRUD Operations ───────────────────────────────────────────────────────

  /// Load all expenses from SQLite and update state
  Future<void> loadExpenses() => _loadExpenses();

  Future<void> _loadExpenses() async {
    final expenses = await _db.getAllExpenses();
    state = expenses;
  }

  /// Add a new expense to the database and prepend to state
  Future<void> addExpense(ExpenseItem expense) async {
    await _db.insertExpense(expense);
    // Prepend for O(1) update — matches DB ordering (desc by timestamp)
    state = [expense, ...state];
  }

  /// Delete an expense by [id] from DB and state
  Future<void> deleteExpense(String id) async {
    await _db.deleteExpense(id);
    state = state.where((e) => e.id != id).toList();
  }

  /// Update an existing expense in DB and reflect change in state
  Future<void> updateExpense(ExpenseItem updated) async {
    await _db.updateExpense(updated);
    state = state.map((e) => e.id == updated.id ? updated : e).toList();
  }

  // ─── Analytics Helpers ─────────────────────────────────────────────────────

  /// Compute spending totals grouped by category.
  /// Returns a Map<categoryName, totalAmount>.
  CategoryBreakdown getCategoryBreakdown() {
    final breakdown = <String, double>{};
    for (final expense in state) {
      breakdown.update(
        expense.category,
        (existing) => existing + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return breakdown;
  }

  /// Compute total spending per day for the current week (Mon–Sun).
  /// Returns a list of 7 doubles (index 0 = Monday, 6 = Sunday).
  WeeklyTotals getWeeklyTotals() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);

    // Initialize 7 zeros
    final totals = List<double>.filled(7, 0.0);

    for (final expense in state) {
      final ts = expense.timestamp;
      final dayOffset = ts
          .difference(weekStart)
          .inDays;
      if (dayOffset >= 0 && dayOffset < 7) {
        totals[dayOffset] += expense.amount;
      }
    }
    return totals;
  }

  /// Get total spending for all expenses
  double get totalSpent =>
      state.fold(0.0, (sum, e) => sum + e.amount);

  /// Get total spending for current month
  double get monthlyTotal {
    final now = DateTime.now();
    return state
        .where(
          (e) => e.timestamp.year == now.year && e.timestamp.month == now.month,
        )
        .fold(0.0, (sum, e) => sum + e.amount);
  }
}

// ─── Global Provider ──────────────────────────────────────────────────────────

/// Global provider for the expense list and analytics
final expenseNotifierProvider =
    NotifierProvider<ExpenseNotifier, List<ExpenseItem>>(
  ExpenseNotifier.new,
);

/// Derived provider: category spending breakdown
final categoryBreakdownProvider = Provider<CategoryBreakdown>((ref) {
  final notifier = ref.watch(expenseNotifierProvider.notifier);
  // Re-evaluate whenever expenses change
  ref.watch(expenseNotifierProvider);
  return notifier.getCategoryBreakdown();
});

/// Derived provider: weekly totals (Mon–Sun)
final weeklyTotalsProvider = Provider<WeeklyTotals>((ref) {
  final notifier = ref.watch(expenseNotifierProvider.notifier);
  ref.watch(expenseNotifierProvider);
  return notifier.getWeeklyTotals();
});

/// Derived provider: total monthly spending
final monthlyTotalProvider = Provider<double>((ref) {
  final notifier = ref.watch(expenseNotifierProvider.notifier);
  ref.watch(expenseNotifierProvider);
  return notifier.monthlyTotal;
});
