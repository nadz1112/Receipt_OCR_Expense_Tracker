# Role & Context
You are a Senior Mobile Flutter Engineer and clean architecture specialist. You are tasked with implementing the Flutter assignments for VKU Cross-Platform Mobile App Development (Week 7: Flutter & Dart Part 1 - Fundamentals & Widget Tree).

## Objectives
1. Build the production-ready **In-Class Lab Exercise: `ExpenseSummaryCard`** widget strictly adhering to Flutter Material 3 standards.
2. Initialize and scaffold the foundation for **Mini-Project 3: On-Device Receipt OCR & Expense Tracker** with local SQLite storage and clean architectural layering.

---

## Task 1: Reusable `ExpenseSummaryCard` (In-Class Lab)

Create a self-contained, highly optimized reusable widget named `ExpenseSummaryCard` with the following requirements:

### Specifications:
1. **Inputs:**
   - `merchant` (String): Merchant/Store name.
   - `amount` (double): Transaction cost.
   - `date` (DateTime): Transaction timestamp.
   - `category` (enum or String, e.g., `food`, `transport`, `shopping`, `utilities`).
   - `onTap` (VoidCallback): Callback when user taps the card.
2. **Visual Layout & Material 3:**
   - Wrap in a Material 3 `Card` with subtle elevation and rounded corners.
   - Wrap the interaction surface in `InkWell` to deliver responsive ripple effects (`onTap`).
   - **Leading:** An icon inside a circular container/avatar (`CircleAvatar` or decorated `Container`) whose background color and icon dynamically reflect the category.
   - **Center Column:** Store name (`merchant`) displayed with bold typography and text truncation (`TextOverflow.ellipsis`), stacked above the formatted date (`dd/MM/yyyy`) using `CrossAxisAlignment.start`.
   - **Trailing:** Amount formatted as Vietnamese Dong currency with dot/comma grouping and currency symbol (e.g., `150.000 đ`) highlighted with prominent color semantics.
3. **Performance:**
   - Use `const` constructors where applicable.
   - Ensure proper padding, zero pixel overflow (`RenderFlex` safe using `Expanded`).

---

## Task 2: Foundation & Data Architecture for Mini-Project 3

Scaffold the initial clean directory structure and local database layer for the Expense Tracker.

### 1. `pubspec.yaml` Dependencies
Configure the project with Dart 3 and necessary packages:
```yaml
name: vku_expense_ocr
description: VKU Receipt OCR & Expense Tracker
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  go_router: ^13.2.0
  google_mlkit_text_recognition: ^0.11.0
  image_picker: ^1.0.7
  sqflite: ^2.3.2
  path: ^1.9.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

### 2. Directory Structure
Generate a clean, scalable folder structure:
```text
lib/
├── core/
│   ├── theme/          # Material 3 ThemeData (seedColor: 0xFF2C4570 - VKU Navy)
│   └── utils/          # Currency formatters, Date utilities
├── models/             # ExpenseItem entity with toMap/fromMap & copyWith
├── services/           # DatabaseHelper (sqflite CRUD operations)
├── widgets/            # ExpenseSummaryCard and reusable UI primitives
└── main.dart
```

### 3. Entity & SQLite Database Implementation
- **Model (`ExpenseItem`):**
  - Fields: `String id`, `String merchant`, `double amount`, `DateTime timestamp`, `String category`, `String? imagePath`.
  - Provide `toMap()` and `fromMap(Map<String, dynamic> map)` for SQLite serialization.
- **Database Service (`DatabaseHelper`):**
  - Singleton pattern.
  - SQLite database named `expenses.db`.
  - Table `expenses` with schema matching `ExpenseItem`.
  - CRUD operations: `insertExpense()`, `getAllExpenses()`, `deleteExpense(String id)`, `updateExpense()`.

---

## Output Requirements
- Write clean, production-ready, fully commented Dart code.
- Adhere strictly to Sound Null Safety and Dart 3 modern standards (`records`, `patterns`, `const` optimization).
- Ensure all resources are properly disposed of where applicable.