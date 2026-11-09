# Icon bài học — 2026-11-10

CMS Studio có bộ chọn 24 icon với tên, tìm không dấu, trạng thái đang chọn và chế độ tự động theo engine đầu tiên có tương tác. Vào **Thuộc tính → Chọn icon bài học**. Bấm **Lưu nháp** để lưu riêng hoặc **Phát hành** để đồng bộ. Icon xuất hiện trên thẻ bài Admin, tiêu đề Studio, mô phỏng điện thoại, checkpoint chưa hoàn thành và đầu bài trên mobile. Checkpoint đã hoàn thành vẫn hiển thị dấu xác nhận kết quả.

`config.lesson_icon` sử dụng JSON đã có; không cần migration, không đổi trạng thái học hay phiên bản cũ. Mã không nhận diện được dùng icon tự động. Lucide và Material Icons được đóng gói sẵn, không cần tải ảnh hoặc thêm thư viện. Chủ đề mới không có minh họa riêng hiển thị icon dự phòng, hỗ trợ các khóa `functions`, `language`, `code`.

App 1.3.8+12 đã chứa bộ icon. Các lần phát hành bài hoặc đổi icon sau đó tự đồng bộ qua Realtime và đồng bộ định kỳ 30 giây khi có mạng. Bản nháp không hiện cho người học, phiên học đang mở giữ phiên bản đã ghim. Engine/icon mới chưa được đóng gói cần cập nhật app một lần.

Các tệp triển khai:

- CMS: `cms/src/lesson-icons.tsx`, `Studio.tsx`, `App.tsx`, `Player.tsx`, `styles.css`.
- Mobile: `lib/data/models/lesson_icon.dart`, `mobile_catalog.dart`, `lib/topic_roadmap.dart`, `lib/journey_app.dart`.
- Phiên bản: `pubspec.yaml`, `lib/data/repositories/learning_repository.dart`.
- Kiểm thử: `cms/src/lesson-icons.test.tsx`, `Studio.test.tsx`, `postgres.test.ts`, `test/lesson_icon_test.dart`.
- Hướng dẫn: `docs/ADMIN_CONTENT_AUTHORING.md`, `VALIDATION.md`.

Kiểm chứng: 76 CMS tests; toàn bộ 324 Flutter tests trước thay đổi icon dự phòng và 21 tests liên quan sau thay đổi đó; Flutter analyze không lỗi; TypeScript/Vite/CMS build, APK debug build, formatter và diff check. PostgreSQL nhúng kiểm tra lưu nháp → phát hành → danh mục người học giữ nguyên icon. Widget test kiểm tra checkpoint và chủ đề mới ở màn hình nhỏ, text lớn. Cài đè và khởi chạy bản 1.3.8 trên Pixel 9; quan sát icon ngân sách/máy tính ở các checkpoint thực tế. Không thay bài hay tiến độ người dùng để thử phát hành.
