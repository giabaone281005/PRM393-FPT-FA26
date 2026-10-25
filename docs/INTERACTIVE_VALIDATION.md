# Kết quả kiểm tra — 23/10/2026

Đợt cập nhật font và giao diện sau báo cáo này đã kiểm tra lại toàn bộ 11 ca
với font nhúng thật. APK hiện tại: 171.044.552 bytes. Đã xác minh giao diện web qua
REA và lưu ảnh mới, khắc phục giới hạn preview ở lần trước. Xem
[STYLE_RECONSTRUCTION.md](STYLE_RECONSTRUCTION.md) cho evidence và kết quả mới.

Flutter 3.47.4, Dart 3.13.3, Windows.

## Đã qua

- `flutter analyze`: không có lỗi hoặc cảnh báo.
- `flutter test`: 11 kiểm thử, tất cả thành công.
  - Quy tắc chấm 12 thử thách, giới hạn giá trị và các tổ hợp miếng bánh.
  - Hoàn thành đủ 3 bước của từng khóa, xóa tiến độ và nhận XP một lần.
  - Không có TextField, Slider hoặc biểu tượng lựa chọn đáp án trong bài học.
  - Kéo khối thực vào đĩa, sửa sai và khôi phục chính xác mô hình đã làm đúng.
  - Kéo ngang và snapping; chạy mô phỏng xe.
  - Chuyển vật từ nhóm B sang A, bảo toàn tổng; kéo dọc cột dữ liệu.
  - Khóa thao tác sau khi đúng; chấm lại trạng thái đã lưu thay vì tin cờ correct.
  - Tiến độ cũ không tự hoàn thành bài tương tác.
  - Cả 12 bước không báo lỗi bố cục ở kích thước 320 × 640.
  - Điều hướng trang chủ và tìm kiếm vẫn hoạt động.
- `flutter build apk --debug`: thành công.
  - Tệp: `build/app/outputs/flutter-apk/app-debug.apk`, 171.036.756 bytes.
- `flutter build web`: thành công, bao gồm Wasm dry run.

## Giới hạn xác minh

- Chưa chạy APK trên điện thoại thật; chưa đo FPS hoặc độ trễ cảm ứng.
- Chưa build hoặc chạy iOS: cần macOS/Xcode.
- Bản web build thành công nhưng trình duyệt kiểm tra không kết nối được preview
  cục bộ (connection refused/timeout), nên chưa kiểm tra trực quan bằng trình duyệt.
- Ảnh PNG trong docs từ phiên bản trước, không đại diện cho màn bài tập hiện tại.

## Thiết kế vận hành

Animation và xem trước khi kéo nằm trong widget riêng; lưu SharedPreferences
khi kết thúc thao tác hoặc thay đổi bước/gợi ý, không lưu theo frame mô phỏng.
Bản này sử dụng Flutter CustomPainter, gesture, drag/drop và AnimationController;
không cần package đồ họa ngoài hoặc WebView. Nút thêm/bớt là thao tác thay thế
cho kéo, không phải các phương án trả lời.
