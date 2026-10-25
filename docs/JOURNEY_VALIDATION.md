# Luồng offline và bảng màu thống nhất — 23/10/2026

Người dùng chọn hồ sơ trên thiết bị, hoạt động offline. Phiên bản 1.1.0+2.

## Đã triển khai

- Mở/tạo hồ sơ → chọn sở thích → nhịp học → hôm nay → thư viện 8 chủ đề.
- 24 thí nghiệm với mô hình riêng, không MCQ hoặc nhập đáp án số.
- Đổi cách thao tác giữa các bước: kéo/thả, xoay, vuốt, ghép, nối, gập,
  điều khiển mô phỏng, dựng thuật toán và quan sát kết quả.
- Tự lưu bước và toàn bộ trạng thái mô hình sau thao tác, định kỳ 15 giây và khi chuyển nền.
- Khôi phục hồ sơ khi mở app, tiếp tục đúng bài/bước. Hồ sơ khác nhau không dùng chung tiến độ.
- Hoàn thành được chấm lại từ cả ba mô hình; lịch sử lưu số lần thử/gợi ý/thời gian.
- Nhận 30 XP lần đầu; ôn lại được ghi lịch sử nhưng không cộng trùng.
- Ghi thất bại giữ bản nháp và cho thử lại. Biên nhận hoàn thành gắn đúng chủ hồ sơ.
- Thời gian dùng milliseconds để không mất các khoảng thao tác dưới một giây.

## Kiểm tra

- `flutter test`: 34 kiểm thử đạt, gồm toàn bộ 8 hành trình, 24 validators,
  layout ở 240px/320px, thao tác thật, lifecycle/resume, đổi hồ sơ,
  sai/thử lại/reset, lỗi ghi dữ liệu và XP không trùng.
- `flutter analyze`: sạch.
- Android debug APK và web build thành công. Chưa xác minh iOS/điện thoại thật.
- Bài mạch điện dùng nguồn và đèn làm linh kiện cố định; chỉ nối hai dây còn thiếu.
  Nối tắt nguồn/đèn được nhận diện. Bài comparator kiểm tra mô hình trên đủ 24 hoán vị.

## Một bảng màu cho mọi màn

| Vai trò | Token REA |
|---|---|
| Nền chính, chữ | #FFFFFF, #000000 |
| Khay, track, viền | #F8F8F8, #E5E5E5, #CCCCCC |
| Chữ phụ, CTA | #666666, #383838 |
| Nhấn, tiến độ | #29CC57 |
| Nền nhấn, chữ xanh | #EAFAEE, #007C23 |

Entry, onboarding, home, topic library/detail, lesson, feedback, completion,
history, profile, dialog/sheet/snackbar dùng cùng `buildAppTheme()`.
Không phân palette tím/xanh dương/cam/vàng cho các chủ đề. State lỗi dùng
biểu tượng và lời nhắc trên nền trung tính. Các màu khác chỉ là dữ liệu thực nghiệm
(RGB, hai loại bi, dấu nối tắt), không phải màu giao diện từng trang.

## Cơ sở REA

Font/CSS nguồn: [STYLE_RECONSTRUCTION.md](STYLE_RECONSTRUCTION.md).
Lượt quan sát màn Sign in công khai:
`ev_8621cd061c24908b62f5294fd09146bad6d7ff59474ae261c1151b4f11b595b7`.
Nguồn có Google/Facebook/Apple/email; app này dùng entry hồ sơ offline theo
lựa chọn người dùng, không sao chép các nút dịch vụ chưa tích hợp.

REA chủ động dùng các thao tác khai báo. Tên An là dữ liệu kiểm tra.
Bundle thêm: `evidence/journey-rea-bundle.json`. Ảnh luồng cuối được lưu trong `docs/journey-*.png`.

Các lần click semantics ngoài viewport hoặc trước khi Flutter tạo cây trợ năng có thể timeout;
không tính các lần thất bại là bằng chứng luồng thành công. Kiểm thử Flutter riêng
bao phủ chạm/kéo thực; REA dùng thao tác bàn phím với nút ngoài viewport khi cần.

## Giới hạn

Không có backend, tài khoản email, đồng bộ thiết bị, AI tutor hoặc cloud backup.
Hồ sơ cục bộ không phải ranh giới bảo mật giữa người cùng dùng thiết bị.
Mô phỏng là mô hình giáo dục đơn giản; chưa đo FPS/touch latency native.
Ứng dụng có tám hành trình hoàn chỉnh hiện có; không tự sinh vô hạn bài mới.

## Luồng UI đã xác nhận

REA `ev_1bf4066d26fbb0bb5598c2f85f0bbdb59f69f63be242a27ee21f6d20dad0f46b` chạy thành công 50 bước: tạo hồ sơ, onboarding, học ba thử thách logic bằng thao tác thật, hoàn thành +30 XP, thư viện, lịch sử, hồ sơ, đóng/mở phiên và reload app. Sau reload, tên An và 30 XP vẫn được giữ. Không có page-error trong cửa sổ quan sát.

APK cuối: 173,026,124 bytes. Manifest ảnh và kết quả: `evidence/journey-verification.json`.
