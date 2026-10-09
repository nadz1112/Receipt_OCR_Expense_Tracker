import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/format_utils.dart';

/// A highly optimized, reusable Material 3 card widget for displaying
/// a single expense summary in a list.
///
/// Features:
/// - Dynamic category icon and color in a circular avatar
/// - Bold merchant name with ellipsis overflow
/// - Formatted date (dd/MM/yyyy)
/// - Vietnamese Dong currency formatting with prominent color
/// - InkWell ripple effect on tap
/// - `const`-friendly construction for performance
class ExpenseSummaryCard extends StatelessWidget {
  /// Merchant or store name displayed prominently
  final String merchant;

  /// Transaction amount in Vietnamese Dong
  final double amount;

  /// Transaction date/time
  final DateTime date;

  /// Category string (food, transport, shopping, utilities, entertainment)
  final String category;

  /// Callback fired when the user taps the card
  final VoidCallback onTap;

  const ExpenseSummaryCard({
    super.key,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Derive dynamic category color and icon
    final categoryColor = AppTheme.categoryColor(category);
    final categoryIcon = AppTheme.categoryIcon(category);

    return Card(
      // Material 3 Card with subtle elevation and rounded corners
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        // Ripple effect — respects Card's rounded corners via Clip.antiAlias
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ── Leading: Category Avatar ──────────────────────────────────
              _CategoryAvatar(
                color: categoryColor,
                icon: categoryIcon,
              ),

              const SizedBox(width: 16),

              // ── Center: Merchant & Date ───────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Merchant name — bold with ellipsis for long names
                    Text(
                      merchant,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Formatted date string
                    Text(
                      FormatUtils.formatDate(date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ── Trailing: Amount ──────────────────────────────────────────
              _AmountLabel(
                amount: amount,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular avatar showing the expense category icon
class _CategoryAvatar extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _CategoryAvatar({
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: color.withOpacity(0.15),
      child: Icon(
        icon,
        color: color,
        size: 22,
      ),
    );
  }
}

/// Trailing label showing the formatted VND amount
class _AmountLabel extends StatelessWidget {
  final double amount;
  final Color color;

  const _AmountLabel({
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      FormatUtils.formatVND(amount),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.3,
          ),
    );
  }
}
