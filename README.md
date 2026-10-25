# Matlingo — học qua thí nghiệm tương tác

Flutter mobile app, tiếng Việt, chạy offline. Luồng hoàn chỉnh: **tạo/mở hồ sơ → chọn sở thích/nhịp học → khám phá chủ đề → ba thí nghiệm → hoàn thành → lịch sử và tiếp tục phiên**.

## Bài học 3D và cập nhật mobile

Ba vòng phát triển chiều sâu local đã thêm gợi ý ba mức có lưu/khôi phục, phản hồi theo điều kiện của mô hình và mẫu khối để so sánh thể tích/bề mặt. Áp dụng cho các bài 3D và hai biểu diễn phân số. Kế hoạch, kiểm tra đã chạy và phần còn chờ Flutter QA: [LESSON_DEPTH_ITERATIONS.md](docs/LESSON_DEPTH_ITERATIONS.md).

Danh mục hiện có **11 chủ đề, 53 hoạt động, 30 cơ chế tương tác**. Đợt 3D thêm khối hộp cho Hình học/Đại số và chủ đề **Trái Đất trong tay bạn** với quả địa cầu lưới tọa độ, mặt cắt ba lớp trầm tích. Kéo để xoay; dùng nút thay thế để đổi góc nhìn, kích thước, tọa độ và thứ tự lớp.

Engine 3D nhỏ viết bằng Dart, vẽ qua Flutter Canvas, chạy offline; chưa có bản đồ địa hình hoặc texture lục địa. Xem [MOBILE_3D.md](docs/MOBILE_3D.md) để biết kiến trúc, kiểm tra và giới hạn. Các bản build và ảnh trước đợt này chưa chứa nội dung 3D mới.

## Bản cài

- APK debug: `build/app/outputs/flutter-apk/app-debug.apk`.
- Phiên bản 1.3.0+4. Dùng Flutter 3.47.4 / Dart 3.13.3.
- iOS có project nhưng cần macOS/Xcode; chưa build hoặc chạy trên thiết bị thật.

```sh
flutter pub get
flutter run
flutter test
flutter analyze
flutter build apk --debug
flutter build web
```

## Nền tảng ban đầu: tám chủ đề, 24 thí nghiệm

| Chủ đề | Ba cách khám phá |
|---|---|
| Logic | Cân khối, vuốt bỏ cặp hai vế, truyền bánh răng |
| Toán học | Tô lát bánh, gập giấy, chia vật vào giỏ |
| Chuyển động | Ngắm/phóng bóng, dựng hành trình, cân mômen |
| Dữ liệu | Đổi cột, phân điểm vào khoảng, chuyển tầng tìm trung bình |
| Hình học | Kéo đỉnh, tạo ảnh đối xứng, xoay/ghép tam giác |
| Lập trình | Dẫn robot tránh vật cản, ghép vòng lặp, xây/chạy mạng comparator |
| Mạch điện | Nối vòng qua nguồn/đèn, thử mạch logic, pha ánh sáng RGB |
| Xác suất | Tạo túi bi theo tỉ lệ, ghép không gian mẫu hai xu, chia vòng quay |

Không có câu hỏi trắc nghiệm, ô nhập đáp án số hoặc trang lý thuyết bắt buộc.
Các nút điều chỉnh là cách thao tác thay thế cho kéo/vuốt, không phải danh sách đáp án.
Gợi ý và giải thích ngắn xuất hiện trong ngữ cảnh thí nghiệm.

## Hồ sơ và phiên học offline

- Mỗi hồ sơ có tên, sở thích, nhịp học, XP, lịch sử và bài đang làm riêng.
- App nhớ hồ sơ đang mở; mở lại tự vào đúng không gian của người học.
- Lưu cả trạng thái từng mô hình, bước học, gợi ý đã dùng, số lần kiểm tra và thời gian hoạt động.
- Tự lưu sau thao tác, định kỳ và khi chuyển nền; có nút lưu ngay và đổi hồ sơ.
- Hoàn thành được kiểm tra từ cả ba mô hình; 30 XP chỉ nhận lần đầu, ôn lại không cộng trùng.
- Nếu ghi thất bại, giữ bản nháp, báo lỗi và cho thử lại; chưa tuyên bố hoàn thành đã lưu.
- Giữ XP bản cũ, nhưng khởi tạo lại thử thách khi nội dung/cơ chế thay đổi.

Đây là hồ sơ cục bộ theo lựa chọn của người dùng, không phải tài khoản cloud hoặc xác thực danh tính. Gỡ app/xóa dữ liệu ứng dụng có thể làm mất dữ liệu; chưa có đồng bộ hay xuất bản sao lưu.

## Thiết kế REA và bảng màu thống nhất

Tất cả màn dùng một hệ font và màu: Cofo Brilliant, Cofo Robert; fallback Noto Sans/Noto Serif cho tiếng Việt; nền trắng, chữ đen, xám trung tính, xanh `#29CC57` và xanh nhạt `#EAFAEE`. Không phân giao diện từng chủ đề bằng các palette khác nhau.

Các màn dùng chung bảng màu giao diện. Minh họa chủ đề có thêm lam, tím và vàng để tạo chiều sâu vật thể; màu đỏ/lam/vàng trong thí nghiệm vẫn phục vụ dữ liệu học tập cần phân biệt (RGB, viên bi hoặc cảnh báo nối tắt).

Giao diện mới gồm **Trang chủ – Chủ đề – Hồ sơ**. Trang chủ có nút học tiếp/chọn chủ đề; tab Chủ đề gom 8 icon dạng khối theo nhóm với tiến độ, thành tựu và lịch sử. Cài đặt giao diện ở header được lưu trên thiết bị. Xem [HOME_TOPICS_PROFILE.md](docs/HOME_TOPICS_PROFILE.md) và [bộ icon](docs/topic-icon-sheet.png).

Header có menu popup dẫn đến Cài đặt, Tặng Premium, Giới thiệu, Trợ giúp và Đăng xuất. Home có box chat chờ nối backend; thẻ chủ đề tự xuống hàng trong khung. Trạng thái, điểm tích hợp và kiểm chứng: [CHAT_AND_SETTINGS_MENU.md](docs/CHAT_AND_SETTINGS_MENU.md).

Hồ sơ hiển thị thời gian, số phiên theo ngày và 7 ngày gần nhất, lưu riêng cho mỗi người học. Xem [DAILY_PROFILE.md](docs/DAILY_PROFILE.md).

Toàn bộ màn dùng khung/lề/header/nút chung và kế thừa tùy chỉnh giao diện. Quy chuẩn, bằng chứng REA và ảnh: [UNIFIED_LAYOUT.md](docs/UNIFIED_LAYOUT.md).

Font, token CSS, ảnh nguồn và giới hạn xác minh: [STYLE_RECONSTRUCTION.md](docs/STYLE_RECONSTRUCTION.md).
Luồng mới và kết quả: [JOURNEY_VALIDATION.md](docs/JOURNEY_VALIDATION.md).
Kế hoạch: [COMPLETE_JOURNEY_PLAN.md](docs/COMPLETE_JOURNEY_PLAN.md).

## Chuyển động và tỷ lệ nút

Chuyển trang hai chiều, đổi bước học, mở/đóng gợi ý và phản hồi nhấn nút dùng một hệ chuyển động chung. Nút chính ôm nội dung, rộng tối đa 320px, vùng chạm tối thiểu 48px; chữ dài được xuống dòng. Robot, cân/đòn bẩy, đèn điện và minh họa phản hồi bằng chuyển động hữu hạn. Tôn trọng tùy chọn giảm chuyển động của hệ thống.

Nguồn ví dụ và kiểm chứng: [MOTION_AND_LAYOUT.md](docs/MOTION_AND_LAYOUT.md).

## Kiến trúc

- `lib/main.dart`: khởi động app.
- `lib/learning_store.dart`: hồ sơ, hàng đợi lưu snapshot, bản nháp và hoàn thành.
- `lib/entry_flow.dart`: màn vào app và onboarding.
- `lib/journey_app.dart`: thư viện, resume, lesson runner, hoàn thành và lịch sử.
- `lib/learning_catalog.dart`: tám chủ đề.
- `lib/experiments/`: 24 mô hình/validator và workspace tương tác.
- `lib/app_theme.dart`: bộ màu/typography/CTA/progress dùng chung.
- `test/`: validator, gesture, layout nhỏ, session/resume, isolation, XP và lỗi lưu.

Canvas, gesture và animation là Flutter native-rendered; không dùng WebView. Không cần engine đồ họa ngoài cho các thí nghiệm 2D này. Chưa đo FPS hoặc độ trễ cảm ứng trên điện thoại.

`lib/challenges.dart` và `lib/interactive_workspace.dart` là mã của bộ 12 thử thách cũ, không tham gia luồng mới.
## Matlingo — nâng cấp từ khảo sát REA

Bản đồ 3 lộ trình qua 8 chủ đề; gợi ý tiếp tục/ôn tập có lý do; thực hành theo lịch sử cục bộ; gợi ý theo trạng thái cho 8 kiểu thí nghiệm. Không có AI online hoặc sinh bài mới trong bản này. Lượt ôn không cộng trùng XP.

Xem [MATLINGO_REA_UPGRADE.md](docs/MATLINGO_REA_UPGRADE.md) để phân biệt bằng chứng Brilliant và thiết kế riêng của ứng dụng.
