# 📱 VKU Receipt OCR & Expense Tracker
> **Mini-Project 2 — Học phần:** Phát triển ứng dụng di động đa nền tảng (Cross-Platform Mobile App Development)  
> **Trường Đại học Công nghệ Thông tin & Truyền thông Việt - Hàn (VKU)**

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)]()

Ứng dụng quản lý tài chính cá nhân thông minh kết hợp nhận diện hóa đơn tự động bằng trí tuệ nhân tạo ngoại tuyến (On-Device OCR) chạy 100% trên thiết bị, bảo mật tuyệt đối dữ liệu tài chính của người dùng.

---

## 🌟 Các Tính Năng Nổi Bật

* 📷 **Quét hóa đơn On-Device (Offline):** Chụp trực tiếp từ Camera hoặc chọn từ Thư viện ảnh. Sử dụng **Google ML Kit Text Recognition** chạy cục bộ không cần kết nối mạng.
* 🧠 **Bộ bóc tách Regex thông minh (Smart Parser):** Tự động nhận diện Tên cửa hàng/đơn vị, Ngày giao dịch (`DD/MM/YYYY`, `YYYY-MM-DD`), và Tổng số tiền thanh toán (hỗ trợ định dạng `VNĐ`, `$`, dấu chấm/phẩy).
* 📝 **Màn hình kiểm tra & Xác nhận (Review Screen):** Cho phép người dùng chỉnh sửa thông tin, phân loại danh mục (`Ăn uống`, `Mua sắm`, `Di chuyển`, `Hóa đơn`, `Giải trí`, `Khác`) và xem chuỗi văn bản gốc (Raw OCR Text) trước khi lưu.
* 📊 **Trực quan hóa chi tiêu (Custom Canvas Charts):**
  - **Donut Chart:** Tỷ lệ phần trăm chi tiêu theo từng danh mục.
  - **Weekly Bar Chart:** Biểu đồ cột chi tiêu 7 ngày gần nhất.
  - Được xây dựng thuần bằng `CustomPainter` của Flutter, tối ưu FPS và không phụ thuộc thư viện bên ngoài.
* 🗄️ **Lưu trữ dữ liệu cục bộ an toàn (SQLite Database):** Quản lý chi tiêu với `sqflite`, hỗ trợ đầy đủ các thao tác Thêm, Sửa, Xóa (vuốt để xóa - swipe-to-delete), Lọc theo danh mục.
* ⚡ **Quản lý trạng thái hiện đại (Riverpod 2):** Sử dụng `NotifierProvider` và các `derived providers` giúp UI phản ứng tức thì và tối ưu hiệu năng render.
* 🎨 **Giao diện chuẩn Material 3 & 100% Tiếng Việt:** Thiết kế hiện đại, tinh gọn với tông màu chủ đạo VKU Navy, mang lại trải nghiệm người dùng liền mạch.

---

## 📦 Cài Đặt File APK Trực Tiếp

Bạn có thể tải và cài đặt trực tiếp file APK Release đã được đóng gói sẵn trong kho lưu trữ:

* **File APK:** [`APK/vku_expense_ocr.apk`](./APK/vku_expense_ocr.apk)
* **Kích thước:** ~24.5 MB (Đã tối ưu R8 Obfuscation & Tree-shaking).
* **Kiến trúc tương thích:** `android-arm64` (chạy trên hầu hết điện thoại Android hiện nay).

### Lệnh cài đặt nhanh qua ADB:
```bash
adb install APK/vku_expense_ocr.apk
```

---

## 🚀 Hướng Dẫn Chạy Từ Mã Nguồn (Development)

### Yêu cầu tiên quyết:
* Flutter SDK: `>=3.24.0`
* Dart SDK: `>=3.5.0`
* Java JDK: Eclipse Temurin JDK 17 (hoặc OpenJDK 17)
* Android SDK Platform: API 34 hoặc 35

### Các bước cài đặt:
1. **Clone repository:**
   ```bash
   git clone https://github.com/nadz1112/Receipt_OCR_Expense_Tracker.git
   cd Receipt_OCR_Expense_Tracker
   ```

2. **Cài đặt các gói phụ thuộc:**
   ```bash
   flutter pub get
   ```

3. **Chạy ứng dụng:**
   ```bash
   flutter run
   ```

4. **Đóng gói file APK:**
   ```bash
   flutter build apk --release --target-platform android-arm64
   ```

---

## 🏗️ Cấu Trúc Dự Án (Project Structure)

```
lib/
├── core/
│   ├── constants/       # Hằng số ứng dụng, danh mục chi tiêu, bảng màu
│   ├── theme/           # Chủ đề Material 3 (VKU Navy Theme)
│   └── utils/           # Định dạng tiền tệ, ngày tháng (Intl VN)
├── models/
│   └── expense_item.dart# Mô hình dữ liệu ExpenseItem
├── routes/
│   └── app_router.dart  # Cấu hình GoRouter điều hướng các màn hình
├── screens/
│   ├── dashboard_screen.dart     # Màn hình chính, tổng quan biểu đồ & danh sách
│   ├── scanner_screen.dart       # Màn hình quét hóa đơn qua Camera / Thư viện
│   └── review_receipt_screen.dart# Màn hình kiểm tra và xác nhận hóa đơn
├── services/
│   ├── database_helper.dart      # Quản lý SQLite database (sqflite)
│   ├── ocr_service.dart          # Dịch vụ nhận diện văn bản (Google ML Kit)
│   └── receipt_parser.dart       # Thuật toán Regex bóc tách thông tin hóa đơn
├── state/
│   └── expense_provider.dart     # Quản lý trạng thái Riverpod 2
└── widgets/
    ├── donut_chart.dart          # Biểu đồ tròn phân loại danh mục (CustomPainter)
    ├── weekly_bar_chart.dart     # Biểu đồ cột 7 ngày trong tuần (CustomPainter)
    └── expense_tile.dart         # Thẻ hiển thị từng giao dịch
```

---

## 📄 Báo Cáo Kỹ Thuật
Xem chi tiết báo cáo kỹ thuật theo chuẩn VKU tại: [`TECHNICAL_REPORT.md`](./TECHNICAL_REPORT.md).

---

## 👨‍💻 Tác Giả & Bản Quyền
* **Kho lưu trữ:** [https://github.com/nadz1112/Receipt_OCR_Expense_Tracker](https://github.com/nadz1112/Receipt_OCR_Expense_Tracker)
* Dự án được phát triển trong khuôn khổ học phần **Phát triển ứng dụng di động đa nền tảng** — Trường Đại học Công nghệ Thông tin & Truyền thông Việt - Hàn (VKU).