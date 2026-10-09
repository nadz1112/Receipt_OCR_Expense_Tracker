/// VKU Expense Tracker — Vietnamese Receipt OCR Parser
///
/// Implements heuristic Regex-based extraction for Vietnamese cash receipts.
/// Handles varying layouts, labels, and decimal notations common in Vietnam.
///
/// Pipeline:
/// ```
/// rawOcrText → ReceiptParser.parse() → ParsedReceipt record
/// ```
library;

/// Structured result from the [ReceiptParser]
class ParsedReceipt {
  /// Extracted total amount (null if not confidently parsed)
  final double? totalAmount;

  /// Extracted transaction date (null if not found)
  final DateTime? date;

  /// Extracted merchant/store name (null if not found)
  final String? merchant;

  /// Confidence score 0.0–1.0 indicating parser reliability
  final double confidence;

  /// Raw extracted text for debugging/display
  final String rawText;

  const ParsedReceipt({
    this.totalAmount,
    this.date,
    this.merchant,
    required this.confidence,
    required this.rawText,
  });

  /// True when confidence is high enough to auto-fill without user correction
  bool get isHighConfidence => confidence >= 0.6;

  @override
  String toString() =>
      'ParsedReceipt(merchant: $merchant, amount: $totalAmount, '
      'date: $date, confidence: $confidence)';
}

/// Heuristic OCR parser for Vietnamese cash receipts.
///
/// Supports extraction of:
/// - Total amount with various Vietnamese payment keywords
/// - Date in dd/MM/yyyy, dd-MM-yyyy, and yyyy-MM-dd formats
/// - Merchant name from the receipt header
class ReceiptParser {
  ReceiptParser._(); // Static utility — no instantiation

  // ─── Amount Extraction Patterns ─────────────────────────────────────────────

  /// Primary pattern: Vietnamese payment keywords followed by numeric amount
  /// Handles both dot and comma as thousands separators
  /// Keywords: total, tong tien, thanh toan, amount due, tien thanh toan, etc.
  static final RegExp _amountPattern = RegExp(
    r'(?:t[oổ]ng\s*ti[eề]n|thanh\s*to[aá]n|total\s*amount|'
    r'amount\s*due|ti[eề]n\s*thanh\s*to[aá]n|grand\s*total|'
    r'total|t[oổ]ng\s*c[oộ]ng|ph[aả]i\s*tr[aả]|'
    r'th[àa]nh\s*ti[eề]n)\s*[:\-]?\s*'
    r'([\d]{1,3}(?:[.,][\d]{3})*(?:[.,][\d]{0,2})?|\d+)',
    caseSensitive: false,
    multiLine: true,
  );

  /// Fallback: detect large standalone currency amounts (≥ 1000)
  /// e.g., "150.000đ", "150,000 VND"
  static final RegExp _standaloneCurrencyPattern = RegExp(
    r'([\d]{1,3}(?:[.,][\d]{3})+)\s*(?:đ|vnd|vnđ|đồng)?',
    caseSensitive: false,
    multiLine: true,
  );

  // ─── Date Extraction Patterns ────────────────────────────────────────────────

  /// Matches dd/MM/yyyy, dd-MM-yyyy, dd.MM.yyyy
  static final RegExp _dateDMY = RegExp(
    r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})\b',
  );

  /// Matches yyyy-MM-dd (ISO 8601)
  static final RegExp _dateISO = RegExp(
    r'\b(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})\b',
  );

  // ─── Merchant Name Heuristics ────────────────────────────────────────────────

  /// Lines to skip as they typically contain boilerplate, not merchant names
  static final RegExp _skipLinePattern = RegExp(
    r'(?:receipt|hóa\s*đơn|invoice|address|địa\s*chỉ|tel|phone|'
    r'fax|email|website|www|mst|tax|số\s*(?:lượng|tt)|qty|quantity|'
    r'total|tổng|thanh\s*toán|cash|tiền|vnd|đồng)',
    caseSensitive: false,
  );

  // ─── Main Parse Entry Point ──────────────────────────────────────────────────

  /// Parse a raw OCR text string and extract receipt fields.
  ///
  /// [rawText]: The OCR-extracted text from the receipt image.
  /// Returns a [ParsedReceipt] with extracted fields and confidence score.
  static ParsedReceipt parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return ParsedReceipt(confidence: 0.0, rawText: rawText);
    }

    final amount = _extractAmount(rawText);
    final date = _extractDate(rawText);
    final merchant = _extractMerchant(rawText);

    // Compute confidence: higher score for more fields successfully extracted
    double confidence = 0.0;
    if (amount != null) confidence += 0.5;
    if (date != null) confidence += 0.25;
    if (merchant != null) confidence += 0.25;

    return ParsedReceipt(
      totalAmount: amount,
      date: date,
      merchant: merchant,
      confidence: confidence,
      rawText: rawText,
    );
  }

  // ─── Private Extraction Helpers ──────────────────────────────────────────────

  /// Extract total amount using keyword-anchored and fallback patterns.
  static double? _extractAmount(String text) {
    // Pass 1: Keyword-anchored extraction (highest confidence)
    final keywordMatch = _amountPattern.firstMatch(text);
    if (keywordMatch != null) {
      final raw = keywordMatch.group(1)!;
      return _parseNumber(raw);
    }

    // Pass 2: Standalone currency fallback — find the largest amount on receipt
    // (receipts usually have the total as the largest number)
    final standaloneMatches = _standaloneCurrencyPattern.allMatches(text);
    double? largest;
    for (final m in standaloneMatches) {
      final parsed = _parseNumber(m.group(1)!);
      if (parsed != null && (largest == null || parsed > largest)) {
        largest = parsed;
      }
    }
    return largest;
  }

  /// Convert a raw number string to double, handling Vietnamese separators.
  ///
  /// Vietnamese format: dots as thousands, commas as decimal (or vice versa)
  /// Examples:
  ///   "150.000"  → 150000.0
  ///   "150,000"  → 150000.0
  ///   "1.500.000"→ 1500000.0
  static double? _parseNumber(String raw) {
    // Remove all whitespace
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return null;

    // Count dots and commas to determine separator role
    final dotCount = '.'.allMatches(cleaned).length;
    final commaCount = ','.allMatches(cleaned).length;

    String normalized;

    if (dotCount > 1) {
      // Multiple dots → dots are thousands separators (e.g., 1.500.000)
      normalized = cleaned.replaceAll('.', '');
    } else if (commaCount > 1) {
      // Multiple commas → commas are thousands separators (e.g., 1,500,000)
      normalized = cleaned.replaceAll(',', '');
    } else if (dotCount == 1 && commaCount == 0) {
      // Single dot — could be decimal OR thousands separator
      // Heuristic: if 3 digits after dot → thousands separator
      final parts = cleaned.split('.');
      if (parts.length == 2 && parts[1].length == 3) {
        normalized = cleaned.replaceAll('.', ''); // thousands
      } else {
        normalized = cleaned; // decimal
      }
    } else if (commaCount == 1 && dotCount == 0) {
      // Single comma — similar heuristic
      final parts = cleaned.split(',');
      if (parts.length == 2 && parts[1].length == 3) {
        normalized = cleaned.replaceAll(',', ''); // thousands
      } else {
        normalized = cleaned.replaceAll(',', '.'); // decimal
      }
    } else if (dotCount == 1 && commaCount == 1) {
      // Both present: last separator is the decimal
      // e.g., "1.500,00" → 1500.00 or "1,500.00" → 1500.00
      final lastDotIdx = cleaned.lastIndexOf('.');
      final lastCommaIdx = cleaned.lastIndexOf(',');
      if (lastDotIdx > lastCommaIdx) {
        // dot is decimal: remove commas
        normalized = cleaned.replaceAll(',', '');
      } else {
        // comma is decimal: remove dots, replace comma with dot
        normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
      }
    } else {
      normalized = cleaned;
    }

    return double.tryParse(normalized);
  }

  /// Extract a date from the receipt text.
  static DateTime? _extractDate(String text) {
    // Try dd/MM/yyyy first (most common on Vietnamese receipts)
    final dmyMatch = _dateDMY.firstMatch(text);
    if (dmyMatch != null) {
      final day = int.tryParse(dmyMatch.group(1)!);
      final month = int.tryParse(dmyMatch.group(2)!);
      final year = int.tryParse(dmyMatch.group(3)!);
      if (day != null && month != null && year != null) {
        try {
          return DateTime(year, month, day);
        } catch (_) {}
      }
    }

    // Try yyyy-MM-dd (ISO 8601)
    final isoMatch = _dateISO.firstMatch(text);
    if (isoMatch != null) {
      final year = int.tryParse(isoMatch.group(1)!);
      final month = int.tryParse(isoMatch.group(2)!);
      final day = int.tryParse(isoMatch.group(3)!);
      if (year != null && month != null && day != null) {
        try {
          return DateTime(year, month, day);
        } catch (_) {}
      }
    }

    return null;
  }

  /// Extract merchant name using header heuristics.
  ///
  /// Strategy: scan the first 5 lines of the receipt, skip lines matching
  /// boilerplate keywords, return the first meaningful line.
  static String? _extractMerchant(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .take(8) // Only look at receipt header
        .toList();

    for (final line in lines) {
      // Skip lines that look like boilerplate
      if (_skipLinePattern.hasMatch(line)) continue;

      // Skip lines that are purely numeric or symbols
      if (RegExp(r'^[\d\s\W]+$').hasMatch(line)) continue;

      // Skip very short lines (e.g., "—", "=====")
      if (line.length < 4) continue;

      // Skip lines containing only uppercase letters that look like codes
      if (RegExp(r'^[A-Z0-9\-_]{2,8}$').hasMatch(line)) continue;

      return _cleanMerchantName(line);
    }

    return null;
  }

  /// Clean and normalize a merchant name string
  static String _cleanMerchantName(String raw) {
    return raw
        .replaceAll(RegExp(r'[*=\-_|]+'), '') // Remove decorative chars
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
