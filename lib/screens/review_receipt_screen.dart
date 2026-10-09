import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/expense_item.dart';
import '../services/receipt_parser.dart';
import '../state/expense_provider.dart';
import '../core/utils/format_utils.dart';

/// Supported expense categories for the dropdown picker
const _categories = [
  'Ăn uống',
  'Di chuyển',
  'Mua sắm',
  'Hóa đơn',
  'Giải trí',
  'Khác',
];

/// Review & Verification Screen
///
/// Allows the user to inspect the OCR-extracted receipt data,
/// correct any parsing errors, and confirm saving to SQLite.
///
/// CRITICAL: Raw OCR is noisy — this screen is mandatory before DB commit.
class ReviewReceiptScreen extends ConsumerStatefulWidget {
  /// Parsed receipt data from OCR pipeline (may be null for manual entry)
  final ParsedReceipt? parsedReceipt;

  const ReviewReceiptScreen({super.key, this.parsedReceipt});

  @override
  ConsumerState<ReviewReceiptScreen> createState() =>
      _ReviewReceiptScreenState();
}

class _ReviewReceiptScreenState extends ConsumerState<ReviewReceiptScreen> {
  // Form management
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Form field controllers
  late final TextEditingController _merchantCtrl;
  late final TextEditingController _amountCtrl;

  // Form field state
  late DateTime _selectedDate;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();

    final parsed = widget.parsedReceipt;

    // Pre-fill controllers with OCR-extracted values (if available)
    _merchantCtrl = TextEditingController(text: parsed?.merchant ?? '');
    _amountCtrl = TextEditingController(
      text: parsed?.totalAmount != null
          ? FormatUtils.formatVND(parsed!.totalAmount!)
              .replaceAll(' đ', '')
              .trim()
          : '',
    );
    _selectedDate = parsed?.date ?? DateTime.now();
    _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // ─── Validation Helpers ─────────────────────────────────────────────────────

  String? _validateMerchant(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tên cửa hàng / địa điểm';
    }
    if (value.trim().length < 2) {
      return 'Vui lòng nhập tối thiểu 2 ký tự';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số tiền';
    }
    final parsed = FormatUtils.parseVNDAmount(value);
    if (parsed == null) {
      return 'Vui lòng nhập số tiền hợp lệ';
    }
    if (parsed <= 0) {
      return 'Số tiền phải lớn hơn 0 đ';
    }
    return null;
  }

  // ─── Date Picker ────────────────────────────────────────────────────────────

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ─── Save Action ────────────────────────────────────────────────────────────

  Future<void> _saveExpense() async {
    // Validate all fields
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final amount = FormatUtils.parseVNDAmount(_amountCtrl.text) ?? 0.0;

      final expense = ExpenseItem.create(
        merchant: _merchantCtrl.text.trim(),
        amount: amount,
        timestamp: _selectedDate,
        category: _selectedCategory.toLowerCase(),
        imagePath: null, // TODO: pass image path from scanner
      );

      // Persist to SQLite and update Riverpod state
      await ref.read(expenseNotifierProvider.notifier).addExpense(expense);

      if (!mounted) return;

      // Success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Đã lưu chi tiêu: ${expense.merchant}'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // Navigate back
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lưu chi tiêu thất bại: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final parsed = widget.parsedReceipt;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm Tra Hóa Đơn'),
        actions: [
          if (parsed != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ConfidenceBadge(confidence: parsed.confidence),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── OCR Raw Text Preview ────────────────────────────────────
              if (parsed != null && parsed.rawText.isNotEmpty)
                _RawTextPreview(rawText: parsed.rawText),

              const SizedBox(height: 24),

              // ── Section Title ───────────────────────────────────────────
              Text(
                'Kiểm Tra & Chỉnh Sửa Chi Tiết',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kết quả nhận diện OCR có thể có sai lệch. Vui lòng kiểm tra lại các trường trước khi lưu.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),

              // ── Merchant Name ───────────────────────────────────────────
              TextFormField(
                controller: _merchantCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên cửa hàng / Đơn vị',
                  prefixIcon: Icon(Icons.store_rounded),
                  helperText: 'Tên cửa hàng, siêu thị hoặc quán ăn',
                ),
                textCapitalization: TextCapitalization.words,
                validator: _validateMerchant,
              ),

              const SizedBox(height: 16),

              // ── Amount ──────────────────────────────────────────────────
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tổng tiền thanh toán (đ)',
                  prefixIcon: Icon(Icons.payments_rounded),
                  suffixText: 'đ',
                  helperText: 'Nhập tổng số tiền cần thanh toán theo VNĐ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                validator: _validateAmount,
              ),

              const SizedBox(height: 16),

              // ── Date Picker ─────────────────────────────────────────────
              _DatePickerField(
                selectedDate: _selectedDate,
                onTap: _selectDate,
              ),

              const SizedBox(height: 16),

              // ── Category Dropdown ───────────────────────────────────────
              _CategoryDropdown(
                value: _selectedCategory,
                categories: _categories,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),

              const SizedBox(height: 32),

              // ── Save Button ─────────────────────────────────────────────
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveExpense,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_isSaving ? 'Đang lưu...' : 'Lưu Chi Tiêu'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Cancel Button ───────────────────────────────────────────
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Hủy bỏ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

/// Badge showing OCR confidence score
class _ConfidenceBadge extends StatelessWidget {
  final double confidence;

  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();
    final color = confidence >= 0.6
        ? Colors.green
        : confidence >= 0.3
            ? Colors.orange
            : Colors.red;

    return Chip(
      label: Text(
        'Độ tin cậy: $pct%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Collapsible preview of raw OCR text
class _RawTextPreview extends StatefulWidget {
  final String rawText;
  const _RawTextPreview({required this.rawText});

  @override
  State<_RawTextPreview> createState() => _RawTextPreviewState();
}

class _RawTextPreviewState extends State<_RawTextPreview> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.text_snippet_outlined,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Văn bản gốc từ OCR',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                widget.rawText,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tappable date picker field
class _DatePickerField extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;

  const _DatePickerField({required this.selectedDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Ngày giao dịch',
          prefixIcon: Icon(Icons.calendar_today_rounded),
          helperText: 'Chạm để thay đổi ngày giao dịch',
        ),
        child: Text(FormatUtils.formatDate(selectedDate)),
      ),
    );
  }
}

/// Category dropdown selector
class _CategoryDropdown extends StatelessWidget {
  final String value;
  final List<String> categories;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.value,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Danh mục chi tiêu',
        prefixIcon: Icon(Icons.category_rounded),
      ),
      items: categories
          .map(
            (cat) => DropdownMenuItem(
              value: cat,
              child: Text(cat),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Vui lòng chọn danh mục' : null,
    );
  }
}
