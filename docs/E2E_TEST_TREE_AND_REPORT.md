# Matlingo — Cây kiểm thử tự động và báo cáo E2E

Ngày thực hiện: 28/10/2026 (Asia/Bangkok).

## 1. Phạm vi

- Kiểm thử luồng **User** trên frontend hiện tại. Admin mới có API, chưa có giao diện quản trị để chạy E2E dashboard.
- Thêm bài integration test Android dùng thao tác UI thật: bấm, nhập và vuốt. Không chèn đáp án vào callback, không sửa XP hay gọi API để vượt qua bài học.
- Tái sử dụng toàn bộ bộ test Flutter hiện có để kiểm tra tài khoản, đồng bộ, engine, giao diện và nội dung.
- Không commit, push, deploy, sửa schema hoặc thao tác dữ liệu backend thật trong lần kiểm thử này.
- Chỉ có hai vai trò nghiệp vụ User và Admin; các hồ sơ học tập không phải actor trẻ em.

## 2. Môi trường và dữ liệu

| Mục | Thực tế |
|---|---|
| Workspace | `D:\Brilliant Clone\brilliant_mobile\repo-history` |
| HEAD khi kiểm tra | `f38f888`; workspace có thay đổi chưa commit, kết quả áp dụng cho working tree |
| Phiên bản trong pubspec | `1.3.2+6` |
| Thiết bị E2E | `emulator-5554`, Android 15 / API 35, android-x64 |
| Chế độ E2E mới | Offline, mount `LearnApp` với `LearningStore` thật; không khởi tạo cloud/engine |
| Lưu trữ | SharedPreferences native, prefix riêng `matlingo.user.e2e.<runId>.` |
| Hồ sơ test | `E2E User`, `E2E Second User` trong prefix riêng |
| Dọn dữ liệu | Xóa riêng các key thuộc prefix của lần chạy trong `finally`; không clear dữ liệu app hoặc phiên Auth cá nhân |
| Backend thật | Không dùng tài khoản cá nhân; chưa có fixture E2E riêng được cung cấp |

Build integration được cài lên emulator bằng package ứng dụng hiện tại. Bài test không kiểm chứng bản release đã phân phối, bootstrap cloud của `main()` hoặc việc khởi động lạnh toàn bộ tiến trình.

## 3. Quy ước bằng chứng

- **PASS / Android E2E:** bài integration chạy trên emulator với UI và lưu trữ native.
- **PASS / Flutter test:** unit/widget test trên máy; các dịch vụ mạng dùng fake/mock theo bài test, không chứng minh dịch vụ thật hoạt động.
- **PASS / Kiểm tra nội dung:** chương trình kiểm tra evaluator/catalog độc lập.
- **BLOCKED:** chưa đủ điều kiện chạy; không coi là PASS.
- **NOT RUN:** chưa chạy trong lần kiểm tra này.

Một integration test có nhiều checkpoint nghiệp vụ. Không cộng số checkpoint vào tổng số bài test Flutter để làm tăng số lượng test đã chạy.

## 4. Cây kiểm thử

```text
Matlingo
├── User
│   ├── A. Tài khoản [Flutter test; cloud thật BLOCKED]
│   │   ├── Đăng nhập/đăng ký: validation, đổi chế độ, loading, chống gửi trùng
│   │   ├── Xác nhận email: mã sai/hết hạn, gửi lại, cooldown
│   │   ├── Khôi phục mật khẩu: nhập mã, retry, cấu hình bật/tắt
│   │   └── Đăng xuất: đóng phiên và không chuyển dữ liệu sang tài khoản khác
│   ├── B. Hồ sơ và onboarding [Android E2E + Flutter test]
│   │   ├── Tên rỗng → báo lỗi, không tạo hồ sơ
│   │   ├── Tên có khoảng trắng → lưu tên đã trim
│   │   ├── Chọn Logic + mục tiêu 10 phút → Trang chủ
│   │   └── Đổi hồ sơ → tiến độ/XP/lịch sử tách biệt
│   ├── C. Khám phá và điều hướng [Android E2E + Flutter test]
│   │   ├── Trang chủ → Chủ đề → Logic → bài học
│   │   ├── Tìm kiếm/lọc/rỗng/xóa tìm kiếm [Flutter test]
│   │   └── Bài đang học → tiếp tục đúng trạng thái [Flutter test]
│   ├── D. Học tập [Android E2E: Logic; Flutter test: 13 chủ đề]
│   │   ├── Trả lời sai → phản hồi → mở gợi ý → sửa đúng
│   │   ├── Logic 1: Chiếc cân bí mật — đủ 4 khối
│   │   ├── Logic 2: Bóc từng lớp — bỏ 3 cặp, gồm thao tác vuốt
│   │   ├── Logic 3: Truyền chuyển động — bánh nhỏ quay 2 vòng
│   │   ├── Logic 4: Giữ nguyên sự cân bằng — bỏ 5 cặp
│   │   ├── Logic 5: Hiệu chuẩn hộp bí mật — từ 1 khối, thêm 5 khối
│   │   ├── Logic 6: Phản ví dụ — A sáng, B tắt
│   │   └── Hoàn thành → 30 XP cá nhân, không còn bản nháp
│   ├── E. Độ bền và phần thưởng [Android E2E + Flutter test]
│   │   ├── Flush → unmount → reload native preferences → tạo store mới
│   │   ├── Giữ hồ sơ, hoàn thành và 30 XP
│   │   ├── Ôn lại đủ Logic → lịch sử thêm lượt, XP vẫn 30
│   │   └── Hồ sơ mới có XP 0 → quay lại hồ sơ đầu vẫn giữ tiến độ
│   ├── F. Cloud [Flutter test; Android cloud thật BLOCKED]
│   │   ├── Tự sao lưu, retry khi offline, restore thành hồ sơ riêng
│   │   ├── Revision cũ bị từ chối, xử lý xung đột hồ sơ
│   │   ├── Retry giữ ID/payload, không cấp XP xác nhận trùng
│   │   └── Nội dung chưa published giữ hàng đợi, không chặn bài tương thích
│   ├── G. AI và code [Flutter test; provider thật NOT RUN]
│   │   ├── Thêm/sửa/xóa/chọn engine, lưu riêng theo tài khoản
│   │   ├── Chat và bảng vẽ
│   │   └── Python/JavaScript: kết quả/lỗi qua adapter mô phỏng
│   └── H. Giao diện [Flutter test]
│       ├── Điện thoại nhỏ, chữ lớn, safe inset, bàn phím
│       ├── Cài đặt, giảm chuyển động, điều hướng quay lại
│       └── Hồ sơ theo ngày, thông báo lỗi và trạng thái chờ
└── Admin
    ├── API backend có trong repository
    └── E2E dashboard: BLOCKED — chưa có giao diện quản trị
```

## 5. Checkpoint của bài Android E2E mới

File: [user_journey_test.dart](<D:/Brilliant Clone/brilliant_mobile/repo-history/integration_test/user_journey_test.dart>).

| ID | Bước và kỳ vọng |
|---|---|
| E01 | Bấm tạo với tên rỗng: có lỗi và chưa có session hồ sơ |
| E02 | Nhập `  E2E User  `: tên lưu là `E2E User` |
| E03 | Chọn Logic, 10 phút: mở HomeShell, đúng mục tiêu |
| E04 | Chọn tab Chủ đề, mở Logic và vào phòng thí nghiệm |
| E05 | Chỉ thêm một khối rồi kiểm tra: báo sai, XP vẫn 0; mở gợi ý |
| E06 | Giải đúng cả 6 hoạt động bằng control UI, gồm thao tác vuốt |
| E07 | Mở CompletionPage; hoàn thành Logic, XP 30, lịch sử 1, không còn draft |
| E08 | Ghi dữ liệu, dựng lại store từ native preferences: đúng profile, Logic và XP |
| E09 | Mở Khám phá lại, giải lại đủ 6 hoạt động |
| E10 | XP vẫn 30; lịch sử 2; lượt ôn tập có XP 0 |
| E11 | Đóng phiên, tạo hồ sơ thứ hai: không có XP, hoàn thành hoặc lịch sử hồ sơ đầu |
| E12 | Đóng phiên, mở lại hồ sơ đầu: giữ Logic, 30 XP và 2 lượt lịch sử |

**E01–E12 đều PASS** trong lần chạy Android cuối. Chúng thuộc cùng một bài integration, không phải 12 test độc lập.

## 6. Kết quả thực thi

| Kiểm tra | Kết quả | Bằng chứng trong workspace |
|---|---|---|
| Flutter analyze | PASS, không có issue tại lần kiểm tra sau khi thêm test | `build/e2e-analysis-result.log` |
| Toàn bộ unit/widget Flutter | PASS — 197 test | `build/e2e-flutter-tests.log` |
| Android User E2E mới | PASS — 1 bài, 12 checkpoint, thời gian test 1 phút 17 giây (không gồm build/cài) | `build/e2e-user-android-final.log` |
| Server/mobile evaluator parity | PASS — 729 ca / 53 hoạt động baseline | `build/e2e-evaluator-parity.log` |
| Tương tác/domain | PASS — 50 kiểm tra | `build/e2e-diverse.log` |
| Chiều sâu bài học | PASS — 2.491 kiểm tra | `build/e2e-depth.log` |
| Không gian/3D/khôi phục | PASS — 17.552 kiểm tra | `build/e2e-space.log` |
| Android debug build thông thường | PASS — build lại sau integration, Gradle 23,9 giây | `build/e2e-debug-build.log` |
| Format bài test mới và diff check | PASS — Dart format không còn thay đổi; diff check cả working tree và hai file mới không có lỗi whitespace | Kiểm tra cuối task |
| Backend handler Deno | NOT RUN — không có `deno` trên PATH hoặc đường dẫn cài mặc định đã kiểm tra | Không thay đổi backend trong task này |
| Cloud E2E thật | BLOCKED — thiếu fixture riêng `E2E_EMAIL`, `E2E_PASSWORD`, `E2E_ID` | Không dùng tài khoản cá nhân |
| Email/OTP đến hộp thư thật | NOT RUN — cần hộp thư test và cấu hình phù hợp | Không suy ra từ test mock |
| AI/code provider thật | NOT RUN — chưa có engine test được cấu hình | Không suy ra từ adapter mock |
| Admin dashboard E2E | BLOCKED — chưa có frontend Admin | Ngoài phạm vi UI hiện tại |

Lần Android đầu thất bại do kịch bản bấm thêm 6 khối ở hoạt động vốn có sẵn 1 khối. Đã sửa thành thêm 5 khối và dùng đúng nhãn “Khám phá lại” khi ôn tập. Đây là sửa kịch bản test; không sửa logic ứng dụng. Lần chuẩn bị chạy lại giữa chừng được dừng để điều chỉnh nhãn; kết luận PASS chỉ lấy từ lần chạy cuối `build/e2e-user-android-final.log`.

## 7. Chạy lại

Chạy trong PowerShell; mọi đường dẫn đều chỉ đến workspace hiện tại.

```powershell
Set-Location -LiteralPath 'D:\Brilliant Clone\brilliant_mobile\repo-history'
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter devices
flutter test 'D:\Brilliant Clone\brilliant_mobile\repo-history\integration_test\user_journey_test.dart' -d emulator-5554 --no-pub --reporter expanded
node 'D:\Brilliant Clone\brilliant_mobile\repo-history\supabase\tests\evaluator_parity.mjs'
dart 'D:\Brilliant Clone\brilliant_mobile\repo-history\tools\check_diverse.dart'
dart 'D:\Brilliant Clone\brilliant_mobile\repo-history\tools\check_depth.dart'
dart 'D:\Brilliant Clone\brilliant_mobile\repo-history\tools\check_space.dart'
flutter build apk --debug
git diff --check
```

Chờ mỗi lệnh Flutter hoàn tất trước khi chạy lệnh Flutter tiếp theo. Bài E2E mới không cần cloud config hoặc secrets. APK tạo bởi integration dành riêng cho chạy test; APK debug thông thường được build lại sau đó.

Bài [phone_readiness_test.dart](<D:/Brilliant Clone/brilliant_mobile/repo-history/integration_test/phone_readiness_test.dart>) có thể kiểm tra Auth, canonical XP và backup thật khi có fixture riêng. Bài này có ghi dữ liệu backend, cần quản lý vòng đời fixture; không đưa mật khẩu vào tài liệu/Git và không dùng tài khoản cá nhân.

## 8. Thay đổi và giới hạn

- Thêm đúng bài test integration mới và báo cáo này; không chỉnh code sản phẩm hoặc test có sẵn.
- Các thay đổi đã có trước task trong `VALIDATION.md`, các test khác và các tài liệu mới được giữ nguyên.
- Bộ test ảnh hiện có tự ghi lại một số PNG trong `docs`; đã đối chiếu trạng thái sạch đầu lượt và lệnh ghi ảnh trong `test/icon_visual_preview_test.dart`, rồi khôi phục riêng 12 ảnh phát sinh từ lần chạy để tránh thay đổi ngoài phạm vi.
- Chưa xác minh cold start sau kill process, máy Android vật lý, iOS, TalkBack hay bàn phím native bằng thao tác thủ công.
- E2E native mới bao phủ toàn bộ chủ đề Logic; 12 chủ đề còn lại có kiểm thử hoàn thành bằng widget/solution fixture, chưa phải thao tác UI native end-to-end cho mọi hoạt động.
- Kết quả không chứng minh toàn hệ thống production đã qua E2E; đặc biệt cloud thật, hộp thư, AI/code và Admin vẫn có giới hạn nêu trên.
