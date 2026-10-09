import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/expense_item.dart';
import '../state/expense_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/format_utils.dart';

/// Expense Detail Screen — shows full details of a single expense.
///
/// Allows deletion with confirmation dialog.
class ExpenseDetailScreen extends ConsumerWidget {
  final String expenseId;
  final ExpenseItem? expense; // Passed via GoRouter 'extra' for instant display

  const ExpenseDetailScreen({
    super.key,
    required this.expenseId,
    this.expense,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Try to find expense in state if not passed directly
    final expenses = ref.watch(expenseNotifierProvider);
    final item = expense ??
        expenses.where((e) => e.id == expenseId).firstOrNull;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi Tiết Chi Tiêu')),
        body: const Center(
          child: Text('Không tìm thấy khoản chi tiêu'),
        ),
      );
    }

    final categoryColor = AppTheme.categoryColor(item.category);
    final categoryIcon = AppTheme.categoryIcon(item.category);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Chi Tiêu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Xóa chi tiêu',
            onPressed: () => _confirmDelete(context, ref, item),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Card ──────────────────────────────────────────────
            _HeroCard(
              item: item,
              categoryColor: categoryColor,
              categoryIcon: categoryIcon,
            ),

            const SizedBox(height: 24),

            // ── Receipt Image ───────────────────────────────────────────
            if (item.imagePath != null)
              _ReceiptImageCard(imagePath: item.imagePath!),

            // ── Detail Fields ───────────────────────────────────────────
            _DetailRow(
              label: 'Cửa hàng / Đơn vị',
              value: item.merchant,
              icon: Icons.store_rounded,
            ),
            _DetailRow(
              label: 'Số tiền thanh toán',
              value: FormatUtils.formatVND(item.amount),
              icon: Icons.payments_rounded,
              valueStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            _DetailRow(
              label: 'Thời gian giao dịch',
              value: FormatUtils.formatDateTime(item.timestamp),
              icon: Icons.calendar_today_rounded,
            ),
            _DetailRow(
              label: 'Danh mục chi tiêu',
              value: ExpenseCategory.fromString(item.category).displayName,
              icon: categoryIcon,
              iconColor: categoryColor,
            ),
            _DetailRow(
              label: 'Mã định danh (ID)',
              value: item.id,
              icon: Icons.fingerprint_rounded,
              valueStyle: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ExpenseItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa Khoản Chi Tiêu'),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${item.merchant}" (${FormatUtils.formatVND(item.amount)}) không?\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(expenseNotifierProvider.notifier)
          .deleteExpense(item.id);
      if (context.mounted) context.pop();
    }
  }
}

/// Hero card showing the main expense summary
class _HeroCard extends StatelessWidget {
  final ExpenseItem item;
  final Color categoryColor;
  final IconData categoryIcon;

  const _HeroCard({
    required this.item,
    required this.categoryColor,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryColor.withOpacity(0.8),
            categoryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.25),
            child: Icon(categoryIcon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            item.merchant,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            FormatUtils.formatVND(item.amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Receipt image preview card
class _ReceiptImageCard extends StatelessWidget {
  final String imagePath;

  const _ReceiptImageCard({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Ảnh chụp hóa đơn',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Image.file(
            File(imagePath),
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(
              height: 80,
              child: Center(child: Text('Không có ảnh')),
            ),
          ),
        ],
      ),
    );
  }
}

/// A labeled detail row with icon
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor ?? colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: valueStyle ??
                        theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
