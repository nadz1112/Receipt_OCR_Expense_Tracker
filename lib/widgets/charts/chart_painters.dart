import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format_utils.dart';
import '../../models/expense_item.dart';

// ─── Donut Chart ──────────────────────────────────────────────────────────────

/// Data point for the donut chart
class DonutSegment {
  final String label;
  final double value;
  final Color color;

  const DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Animated category donut chart using pure CustomPainter.
///
/// NO third-party charting libraries — only Canvas2D drawing APIs.
/// Animates from 0.0 → 1.0 sweep via [AnimationController].
class DonutChart extends StatefulWidget {
  /// Category spending data
  final Map<String, double> categoryBreakdown;

  /// Outer radius of the donut
  final double size;

  const DonutChart({
    super.key,
    required this.categoryBreakdown,
    this.size = 200,
  });

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryBreakdown != widget.categoryBreakdown) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Build DonutSegment list from category breakdown
  List<DonutSegment> _buildSegments() {
    final total = widget.categoryBreakdown.values
        .fold(0.0, (sum, v) => sum + v);
    if (total == 0) return [];

    return widget.categoryBreakdown.entries
        .where((e) => e.value > 0)
        .map(
          (e) => DonutSegment(
            label: ExpenseCategory.fromString(e.key).displayName,
            value: e.value / total,
            color: AppTheme.categoryColor(e.key),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final segments = _buildSegments();
    final total = widget.categoryBreakdown.values
        .fold(0.0, (sum, v) => sum + v);

    if (segments.isEmpty) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'Chưa có dữ liệu',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Animated Donut ──────────────────────────────────────────────
        AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            return CustomPaint(
              size: Size(widget.size, widget.size),
              painter: DonutChartPainter(
                segments: segments,
                progress: _animation.value,
                totalLabel: FormatUtils.formatVNDCompact(total),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // ── Legend ──────────────────────────────────────────────────────
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: segments.map((seg) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: seg.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${seg.label} ${(seg.value * 100).round()}%',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// CustomPainter for the animated donut chart
class DonutChartPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double progress; // 0.0 → 1.0 animation value
  final String totalLabel;

  DonutChartPainter({
    required this.segments,
    required this.progress,
    required this.totalLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 28.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start from the top (-π/2) going clockwise
    double startAngle = -math.pi / 2;
    const gap = 0.04; // Small gap between segments (radians)

    for (final segment in segments) {
      // Apply animation progress to sweep
      final sweepAngle = (2 * math.pi * segment.value - gap) * progress;

      paint.color = segment.color;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      startAngle += 2 * math.pi * segment.value;
    }

    // ── Center Label ────────────────────────────────────────────────────
    _drawCenterLabel(canvas, center, totalLabel);
  }

  void _drawCenterLabel(Canvas canvas, Offset center, String label) {
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C4570),
            ),
          ),
          const TextSpan(
            text: '\nTotal',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.segments != segments;
}

// ─── Weekly Bar Chart ─────────────────────────────────────────────────────────

/// Animated weekly bar chart using pure CustomPainter.
///
/// Draws 7 rounded vertical bars (Mon–Sun) with day labels via TextPainter.
/// NO third-party charting libraries used.
class WeeklyBarChart extends StatefulWidget {
  /// Spending totals for each day (index 0 = Monday, 6 = Sunday)
  final List<double> weeklyTotals;

  const WeeklyBarChart({
    super.key,
    required this.weeklyTotals,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeklyTotals != widget.weeklyTotals) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(double.infinity, 160),
          painter: WeeklyBarChartPainter(
            weeklyTotals: widget.weeklyTotals,
            progress: _animation.value,
            barColor: theme.colorScheme.primary,
            todayColor: const Color(0xFF2C4570),
            labelColor:
                theme.colorScheme.onSurface.withOpacity(0.6),
            todayIndex: DateTime.now().weekday - 1,
          ),
        );
      },
    );
  }
}

/// CustomPainter for weekly bar chart
class WeeklyBarChartPainter extends CustomPainter {
  final List<double> weeklyTotals;
  final double progress;
  final Color barColor;
  final Color todayColor;
  final Color labelColor;
  final int todayIndex;

  static const _dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  const WeeklyBarChartPainter({
    required this.weeklyTotals,
    required this.progress,
    required this.barColor,
    required this.todayColor,
    required this.labelColor,
    required this.todayIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weeklyTotals.isEmpty) return;

    final maxVal = weeklyTotals.reduce(math.max);
    if (maxVal == 0) {
      _drawEmptyState(canvas, size);
      return;
    }

    const labelHeight = 20.0;
    const barPadding = 10.0;
    final chartHeight = size.height - labelHeight - barPadding;

    final barWidth = size.width / 7 - barPadding;

    for (int i = 0; i < 7; i++) {
      final x = i * (size.width / 7) + barPadding / 2;
      final normalized = weeklyTotals[i] / maxVal;
      final barHeight = chartHeight * normalized * progress;

      final isToday = i == todayIndex;
      final color = isToday ? todayColor : barColor.withOpacity(0.65);

      // Draw rounded bar
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          chartHeight - barHeight,
          barWidth,
          barHeight,
        ),
        const Radius.circular(6),
      );

      canvas.drawRRect(
        barRect,
        Paint()..color = color,
      );

      // Draw day label
      _drawLabel(
        canvas,
        _dayLabels[i],
        Offset(x + barWidth / 2, size.height - labelHeight + 2),
        isToday: isToday,
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset center, {
    bool isToday = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          color: isToday ? todayColor : labelColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, center - Offset(tp.width / 2, 0));
  }

  void _drawEmptyState(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'Chưa có chi tiêu trong tuần này',
        style: TextStyle(
          fontSize: 12,
          color: labelColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(
        size.width / 2 - tp.width / 2,
        size.height / 2 - tp.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant WeeklyBarChartPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.weeklyTotals != weeklyTotals;
}
