# MINI-PROJECT SHORT TECHNICAL REPORT
**Course:** Cross-Platform Mobile App Development (VKU)  
**Mini-Project Title:** Mini-Project 2 — Ứng Dụng Nhận Diện Hóa Đơn On-Device & Quản Lý Chi Tiêu Cá Nhân (VKU Expense OCR)  
**Team / Student Name:** [Tên Nhóm / Tên Sinh Viên]  
**Submission Date:** [DD/MM/YYYY]  

---

## 1. THÔNG TIN CHUNG & ĐƯỜNG DẪN BÀN GIAO (GENERAL INFORMATION & DELIVERABLE LINKS)
* **Thành viên nhóm (Team Members):**
  1. [Họ và Tên Sinh Viên 1] — MSSV: [22ITxxx] — Vai trò: [Trưởng nhóm / Kiến trúc UI & State Management] — Đóng góp: [50%]
  2. [Họ và Tên Sinh Viên 2] — MSSV: [22ITyyy] — Vai trò: [Thành viên / Xử lý On-Device OCR & SQLite Database] — Đóng góp: [50%]
* **🔗 Đường dẫn tải file APK (APK Download Link):**
  - File nội bộ: `d:\DaNentang\Receipt_OCR_&_Expense_Tracker\APK\vku_expense_ocr.apk`
  - Kích thước tệp: ~24.5 MB (Tối ưu hóa Release Mode R8 & ProGuard, kiến trúc `android-arm64`)
  - Đường dẫn Google Drive / Cloud: [Dán link tải APK tại đây]
* **💻 GitHub Repository:** [https://github.com/nadz1112/Receipt_OCR_Expense_Tracker]
* **🎥 Video Demo (Optional):** [https://youtu.be/xxx]

---

## 2. BẢNG KIỂM TÍNH NĂNG ĐÃ THỰC HIỆN (FEATURE IMPLEMENTATION CHECKLIST)

| STT | Tính năng yêu cầu (Required Feature) | Trạng thái (Status) | Chi tiết triển khai kỹ thuật (Implementation Details) |
|:---:|:---|:---:|:---|
| **1** | **Chụp ảnh & Chọn hóa đơn từ thư viện** | ✅ Hoàn thành (100%) | Sử dụng `image_picker` cho phép chụp trực tiếp từ camera thiết bị hoặc chọn ảnh hóa đơn có sẵn từ thư viện ảnh. Hỗ trợ preview ảnh trực quan. |
| **2** | **On-Device OCR (Không cần Internet)** | ✅ Hoàn thành (100%) | Tích hợp `google_mlkit_text_recognition` chạy mô hình nhận diện ký tự trực tiếp trên thiết bị (On-Device), bảo mật 100% dữ liệu tài chính của người dùng, tốc độ xử lý tức thì (< 1 giây). |
| **3** | **Bóc tách thông tin tự động (Regex Parser)** | ✅ Hoàn thành (100%) | Module `ReceiptParser` bóc tách tự động: <br>• **Tổng số tiền:** Nhận diện ký hiệu tiền tệ (`đ`, `VND`, `$`), dấu phân tách hàng nghìn/thập phân. <br>• **Ngày giao dịch:** Nhận diện định dạng `DD/MM/YYYY`, `YYYY-MM-DD`,... <br>• **Tên đơn vị/cửa hàng:** Lọc bỏ tiêu đề rác, trích xuất tên thương hiệu đầu hóa đơn. |
| **4** | **Màn hình xác nhận & chỉnh sửa (Review)** | ✅ Hoàn thành (100%) | Cho phép người dùng kiểm tra thông tin bóc tách trước khi lưu, sửa đổi số tiền, đổi danh mục chi tiêu (`Ăn uống`, `Mua sắm`, `Di chuyển`, `Hóa đơn`, `Giải trí`, `Khác`), xem lại toàn bộ văn bản gốc (Raw OCR Text). |
| **5** | **Lưu trữ dữ liệu cục bộ (Local SQLite)** | ✅ Hoàn thành (100%) | Sử dụng `sqflite` với cấu trúc bảng `expenses` chuẩn hóa (id, merchant, amount, category, date, raw_text, created_at). Hỗ trợ đầy đủ các thao tác CRUD và truy vấn tổng hợp theo tháng/tuần. |
| **6** | **Trực quan hóa chi tiêu (Data Visualization)** | ✅ Hoàn thành (100%) | Vẽ biểu đồ tự dựng bằng `CustomPainter` mượt mà, không phụ thuộc thư viện ngoài: <br>• **Donut Chart:** Tỷ lệ phần trăm chi tiêu theo từng danh mục. <br>• **Weekly Bar Chart:** Biểu đồ cột tổng chi tiêu 7 ngày gần nhất. |
| **7** | **Bộ lọc & Quản lý danh sách giao dịch** | ✅ Hoàn thành (100%) | Hiển thị danh sách chi tiêu phân nhóm theo ngày, hỗ trợ lọc theo danh mục, tính năng vuốt để xóa (Dismissible Swipe-to-delete) có hộp thoại xác nhận. |
| **8** | **Ngôn ngữ & Tiêu chuẩn giao diện** | ✅ Hoàn thành (100%) | 100% giao diện, thông báo lỗi, trạng thái và tài liệu được chuyển đổi sang tiếng Việt chuẩn. Áp dụng chuẩn thiết kế Material 3 hiện đại, màu sắc trực quan, hỗ trợ giao diện mượt mà. |

---

## 3. KIẾN TRÚC HỆ THỐNG & QUẢN LÝ TRẠNG THÁI (SYSTEM ARCHITECTURE)

### 3.1. Sơ đồ luồng dữ liệu (Architecture Flow)
```
[Camera / Gallery] 
       │
       ▼ (Ảnh hóa đơn)
[Google ML Kit Text Recognition] ── (On-Device, Offline)
       │
       ▼ (Chuỗi văn bản thô - Raw Text)
[ReceiptParser Engine] ───────────── (Thuật toán Regex bóc tách Số tiền, Ngày, Cửa hàng)
       │
       ▼ (ExpenseItem dự kiến)
[ReviewReceiptScreen] ────────────── (Xác thực Form, chỉnh sửa & chọn danh mục)
       │
       ▼ (Lưu dữ liệu)
[Riverpod State (ExpenseNotifier)] ── (Cập nhật State toàn cục)
       │
       ▼ (Persist)
[SQLite Local Database (sqflite)]
       │
       ▼ (Notify Derived Providers)
[DashboardScreen: Donut Chart, Weekly Bar Chart, Expense List]
```

### 3.2. Quản lý trạng thái (State Management với Riverpod 2)
* **`expenseListProvider` (`NotifierProvider<ExpenseNotifier, List<ExpenseItem>>`):** Quản lý danh sách chi tiêu gốc, đồng bộ 2 chiều với SQLite database.
* **`categoryBreakdownProvider` (`Provider`):** Derived Provider tính toán tổng số tiền và tỷ lệ phần trăm theo từng nhóm chi tiêu để hiển thị lên Biểu đồ tròn (Donut Chart).
* **`weeklyTotalsProvider` (`Provider`):** Derived Provider tổng hợp số tiền đã chi tiêu trong 7 ngày gần nhất để vẽ Biểu đồ cột (Weekly Bar Chart).
* **`monthlyTotalProvider` (`Provider`):** Derived Provider tính toán tổng chi tiêu lũy kế trong tháng hiện tại.

---

## 4. HƯỚNG DẪN CÀI ĐẶT & CHẠY ỨNG DỤNG (REPRODUCIBILITY GUIDE)

### Cách 1: Cài đặt trực tiếp file APK (Khuyến nghị cho chấm điểm & Test nhanh)
1. Sao chép file APK từ thư mục dự án:  
   `d:\DaNentang\Receipt_OCR_&_Expense_Tracker\APK\vku_expense_ocr.apk`
2. Chuyển file APK vào điện thoại Android hoặc cài đặt qua Android Emulator bằng lệnh ADB:
   ```bash
   adb install "d:\DaNentang\Receipt_OCR_&_Expense_Tracker\APK\vku_expense_ocr.apk"
   ```
3. Mở ứng dụng **VKU Expense OCR** trên điện thoại và cấp quyền Camera / Bộ nhớ khi quét hóa đơn.

### Cách 2: Chạy từ mã nguồn Flutter (Local Development)
1. **Yêu cầu môi trường:**
   - Flutter SDK: `^3.24.0` hoặc mới hơn
   - Dart SDK: `^3.5.0`
   - Android SDK API: 34 hoặc 35
   - Java JDK: Eclipse Temurin JDK 17 (hoặc OpenJDK 17)
2. **Các bước thực thi:**
   ```bash
   # Di chuyển vào thư mục dự án
   cd C:\BuildTemp\vku_expense_ocr

   # Cài đặt toàn bộ dependencies
   flutter pub get

   # Chạy ứng dụng trên thiết bị / máy ảo kết nối
   flutter run --release
   ```

---

## 5. BÀI HỌC KINH NGHIỆM & KẾT LUẬN (LESSONS LEARNED & KEY TAKEAWAYS)
1. **Ưu thế của On-Device Machine Learning:** Sử dụng Google ML Kit hoàn toàn ngoại tuyến loại bỏ hoàn toàn chi phí duy trì API Server, đảm bảo thời gian phản hồi tức thì và giải quyết trọn vẹn bài toán bảo mật dữ liệu nhạy cảm của người dùng.
2. **Xử lý bất đồng bộ & Tối ưu hiệu năng bộ nhớ:** Khi tích hợp mô hình AI trên nền tảng di động, cần tối ưu heap bộ nhớ của JVM/Gradle và áp dụng các quy tắc R8/ProGuard nhằm loại trừ các module thừa, giúp giảm kích thước tệp APK từ hơn 70MB xuống chỉ còn 24.5MB.
3. **Kiến trúc phần mềm phân tầng rõ ràng:** Tách biệt rành mạch giữa UI (Presentation), Logic xử lý nghiệp vụ/State (Riverpod) và Cơ sở dữ liệu (SQLite) giúp ứng dụng hoạt động ổn định, dễ bảo trì và mở rộng thêm các tính năng như đồng bộ đám mây hoặc xuất báo cáo Excel/PDF trong tương lai.