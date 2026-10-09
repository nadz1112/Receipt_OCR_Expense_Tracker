# Role & Context
You are a Principal Flutter Engineer specializing in Computer Vision on edge devices, reactive state management (Riverpod 2), declarative routing (GoRouter), and CustomPainter GPU graphics.

You are tasked with executing the **Mini-Project 3 Final Sprint** based on the requirements of VKU Cross-Platform Mobile App Development (Week 8: State Management, Routing & Platform Channels).

---

## Mini-Project 3 System Pipeline & Core Requirements

Connect the entire data and processing pipeline:
```
Camera Capture (image_picker)
       ↓
ML Kit OCR (google_mlkit_text_recognition)
       ↓
ReceiptParser (Dart Regex Heuristics Engine)
       ↓
Review & Verification Screen (CRITICAL: Form Validation & Manual Correction)
       ↓
Local SQLite Storage (sqflite)
       ↓
State Management (Riverpod 2 NotifierProvider)
       ↓
Animated Charts (CustomPainter: Donut & Weekly Bar Charts)
```

---

## Key Modules to Implement

### 1. Robust Vietnamese Receipt Regex Parser (`ReceiptParser`)
Vietnamese cash receipts feature varying layouts, labels, and decimal notations (e.g., `TOTAL: 150.000`, `Tổng tiền: 150,000 đ`, `Thanh toán: 150000`, `Tiền thanh toán: 85.000đ`).
- Implement `ReceiptParser.parse(String rawText)` returning a record or parsed model containing:
  - `double? totalAmount`: Regex extraction matching Vietnamese payment keywords (`total`, `tong tien`, `thanh toan`, `amount due`, `thanh tien`) coupled with multi-format number extraction (handling both comma and dot thousands separators).
  - `DateTime? date`: Regex extraction for patterns like `dd/MM/yyyy`, `dd-MM-yyyy`, `yyyy-MM-dd`.
  - `String? merchant`: Heuristic parser extracting header text lines or fallback string.
- Provide defensive fallback to manual entry when heuristics do not meet high confidence.

### 2. Mandatory Review & Verification Screen (`ReviewReceiptScreen`)
*Per project requirements, raw OCR is noisy and cannot be committed directly to DB.*
- Create a dedicated screen/form allowing the user to review the captured receipt photo alongside the extracted fields.
- **Form Architecture:**
  - `Form` with `GlobalKey<FormState>()` and `autovalidateMode: AutovalidateMode.onUserInteraction`.
  - `TextFormField` for Merchant Name with non-empty validation.
  - `TextFormField` for Total Amount with numeric validation (must be positive valid amount, handling currency formatting).
  - Date Picker field for updating the timestamp.
  - Category dropdown selector (`Food`, `Transport`, `Shopping`, `Utilities`, `Entertainment`).
- On validation success: Save to SQLite, dispatch update through Riverpod state, trigger feedback `SnackBar`, and navigate back via `context.pop()`.

### 3. Declarative Routing with `GoRouter`
- Implement `appRouter` utilizing `ShellRoute` for persistent bottom navigation:
  - Tab 1: `/dashboard` (`DashboardScreen` - displaying summary and animated charts).
  - Tab 2: `/scanner` (`ScannerScreen` - initiating camera and triggering OCR pipeline).
  - Subroute: `/review` (`ReviewReceiptScreen` passing parsed receipt arguments).
  - Subroute: `/expense/:id` (`ExpenseDetailScreen`).

### 4. Reactive State Management with Riverpod 2
- Implement `ExpenseNotifier` extending `Notifier<List<ExpenseItem>>` with global `expenseNotifierProvider`.
- Expose methods: `addExpense()`, `deleteExpense()`, `loadExpenses()`, `getCategoryBreakdown()`, `getWeeklyTotals()`.
- Use `ref.watch()` in `ConsumerWidget`s to ensure selective rebuilds and 120 FPS performance.

### 5. Custom Canvas Drawing (`CustomPainter`)
*Do NOT use third-party charting libraries (fl_chart, etc.). Implement pure hardware-accelerated CustomPainter.*
1. **Animated Category Donut Chart (`DonutChartPainter`):**
   - Accept category percentages, colors, and an animation `progress` value ($0.0 \rightarrow 1.0$).
   - Draw arcs using `canvas.drawArc(rect, startAngle, sweepAngle, false, paint)` with `PaintingStyle.stroke`.
   - Animate smoothly via `AnimationController` and `AnimatedBuilder`.
2. **Weekly Bar Chart (`WeeklyBarChartPainter`):**
   - Draw rounded vertical bars representing expenses across the 7 days of the week.
   - Render text labels for days (Mon - Sun) directly using `TextPainter`.

### 6. Platform Channels Bonus Implementation
- Implement a simple `MethodChannel` (`vn.edu.vku/device_info`) to fetch battery percentage or trigger native haptic feedback upon successful receipt scan.

---

## Deliverables & Handover Checklist
Ensure the final output provides complete, clean Dart files structured as follows:
- `lib/services/receipt_parser.dart`
- `lib/state/expense_provider.dart`
- `lib/routes/app_router.dart`
- `lib/screens/review_receipt_screen.dart`
- `lib/widgets/charts/donut_chart_painter.dart`
- `lib/widgets/charts/weekly_bar_chart_painter.dart`
- A technical documentation template for the **2–4 Page Technical Report (PDF)** outlining:
  1. Architecture diagram.
  2. OCR Regex heuristics mapping table.
  3. Light/Dark mode screenshots specification.
  4. Known technical limitations.