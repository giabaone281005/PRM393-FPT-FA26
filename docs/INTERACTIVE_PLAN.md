# Kế hoạch bài toán tương tác trên mobile

Quyết định: tiếp tục Flutter/Dart hiện có, dùng CustomPainter, GestureDetector,
DragTarget/Draggable và animation của Flutter. Không thêm WebView hay chuyển
sang React Native khi dự án không có phần giao diện React để tái sử dụng.
Impeller do Flutter và nền tảng lựa chọn; FPS phải đo bằng profile trên máy thật.

## Các task

- [x] T1 — Chốt kiến trúc và tiêu chí nghiệm thu.
- [x] T2 — Tách mô hình thử thách, giới hạn thao tác và quy tắc kiểm tra.
- [x] T3 — Xây bốn bộ tương tác có vùng chạm rộng, snapping, phản hồi trực quan,
  nút điều chỉnh thay thế kéo thả và hỗ trợ ngữ nghĩa truy cập.
- [x] T4 — Đổi toàn bộ 12 thử thách; lưu trạng thái phiên bản mới, bỏ đáp án
  trắc nghiệm và nhập số, giữ gợi ý, thử lại, hoàn thành và XP một lần.
- [x] T5 — Test hành vi và tiến độ; analyze; build web và APK debug.

## Tiêu chí nghiệm thu

- Mỗi thử thách được giải bằng thao tác lên mô hình, không có danh sách đáp án.
- Cân: thả khối lên đĩa hoặc kéo khối ra; phương trình có mô hình x + 3 = 10.
- Phân số: chạm các miếng bánh; chia đều: chuyển bánh giữa hai người.
- Chuyển động: kéo vị trí dự đoán hoặc tốc độ, chạy mô phỏng để quan sát.
- Dữ liệu: kéo mốc trung vị, chiều cao cột hoặc chuyển sách để cân bằng.
- Trạng thái đúng được tính từ mô hình, không tin cờ correct lưu trước đó.
- Lưu khi kết thúc thao tác, không ghi bộ nhớ ở từng frame animation.
- Tiến độ cũ được chuyển về đầu bước hiện tại; không kế thừa đáp án cũ.
- Các bài hoạt động trên màn hình rộng 320px, có thể sửa sai và tiếp tục.

## Kiểm tra ngoài môi trường Windows

iOS cần macOS/Xcode. Đánh giá 60/120 FPS và touch latency cần chạy profile
trên điện thoại thật, gồm Android cấu hình thấp và thiết bị màn hình 120Hz.
Không coi debug APK hoặc web preview là bằng chứng hiệu năng mobile.
