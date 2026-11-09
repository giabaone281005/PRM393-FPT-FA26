# Quản lý nội dung và tạo bài bằng Gemini

Cập nhật 07/11/2026. Mobile mới: **1.3.4+8** (bài lựa chọn hỗ trợ từ 1.3.3+7).

## CMS chuyên biệt mới

Entry Admin Web hiện chuyển tới **Matlingo Studio** tại `/cms/`, ứng dụng React độc lập. Đăng nhập Admin hiện có hoặc chọn **Khám phá không gian mẫu** để trải nghiệm mà không sửa dữ liệu thật.

Thiết kế bài bằng cách kéo component từ kho vào trang, chỉnh trực tiếp nội dung, cấu hình đáp án ở **Thuộc tính** và thử ngay trên điện thoại mô phỏng. Chat Gemini hỏi kiến thức, chèn phản hồi vào bài và soạn lại các component sau bước duyệt. Không còn dùng danh sách slide làm giao diện biên tập chính.

CMS dùng các RPC/Edge Functions hiện có, giữ phân quyền máy chủ và phiên bản nội dung. Mã nguồn, lệnh chạy, đóng gói cùng entry Admin và giới hạn mô phỏng được ghi trong `cms/README.md`. Các phần dưới đây mô tả hợp đồng nội dung và giao diện Flutter cũ được giữ lại để tương thích.

## Xưởng tạo bài học theo slide

Bài học theo slide cần mobile **1.3.4+8**. Admin Web mới chạy tại `http://127.0.0.1:8088` trên máy phát triển.

1. Đăng nhập Admin → **Tạo bài học**, chọn chủ đề → **Tạo bài học theo slide**.
2. Đặt tên bài, thêm và sắp xếp slide: văn bản/hình ảnh, trắc nghiệm, kéo thả ghép cặp hoặc đồ thị đường thẳng `y = a*x + b` có thanh trượt.
3. Điền nội dung và cấu hình bằng form. Khóa đáp án/tham số cần giữ, nhập yêu cầu rồi dùng Gemini soạn nội dung. Gemini giữ số slide, thứ tự, loại tương tác, số lựa chọn/số cặp và các tham số đã khóa. Địa chỉ ảnh do admin chọn.
4. Chơi thử trước khi phát hành. Bản nháp được tự lưu riêng; phát hành tạo phiên bản nội dung mới. Chủ đề phải đang hoạt động để xuất hiện trong danh mục người học.

Dịch vụ `author-lesson` v2 đã hỗ trợ thiết kế slide và vẫn nhận yêu cầu tạo bài lựa chọn cũ. Migrations bổ sung `20261112000000_slide_cms_engines.sql` và `20261113000000_builder_payload_authority.sql` đã có trên máy chủ. Không chỉnh sửa migration cũ.

Kiểm tra tiếp tục ngày 07/11/2026: analyze và 254 test Flutter đạt; 11 test author handler đạt, gồm giữ khóa, từ chối đổi engine/ID/số phần tử và giới hạn mục tiêu đồ thị. Bộ SQL slide chạy trên database thật trong transaction hoàn tác, kiểm tra draft/RLS, quyền admin, retry/conflict, xuất bản, tương thích mobile cũ, chấm đúng/sai và thưởng XP canonical. Chrome headless chạy đạt các test Admin/nội dung/slide với repository mô phỏng; kết quả tại `build/admin-headless-20261107-093534/`. Bản web và APK debug có cấu hình cloud đã build thành công; APK tại `build/app/outputs/flutter-apk/app-debug.apk`. Đây không phải xác nhận một lượt Gemini thật qua giao diện trình duyệt hay kiểm thử trên điện thoại vật lý.

## Sử dụng

1. Mở Admin → Chủ đề → Thêm chủ đề. Mã được tự tạo; chọn biểu tượng, nhập tên, mô tả, môn học và lời mời khám phá. Bản xem trước phản ánh tên, mô tả và biểu tượng.
2. Chọn **Bài học** trên thẻ/dòng chủ đề → **Thêm bài tương tác**.
3. Có thể nhập thủ công hoặc nhập yêu cầu ở **Soạn bài cùng Gemini**, ví dụ: “Tạo bài phân số lớp 4: chia pizza thành 8 phần, chọn một nửa và giải thích bằng phép chia”.
4. Gemini điền bản nháp vào form. Kiểm tra kiến thức, câu hỏi, các lựa chọn, chỉ số đáp án/lý do đúng (trong form bắt đầu từ 1), gợi ý và lời giải. Chọn **Chơi thử**.
5. Chọn **Lưu và phát hành**. Bản nháp AI không tự xuất bản. Chủ đề cần trạng thái **Đang hoạt động** và ít nhất một bài đang hiển thị để xuất hiện trên mobile.
6. Biên tập bài đã có để sửa, thay thứ tự, lưu trữ hoặc khôi phục. Xóa/lưu trữ ẩn bài khỏi danh mục mới, giữ phiên học và lịch sử điểm.

Mẫu bài mới hiện hỗ trợ **chọn đáp án + chọn lý do**. Mô phỏng đã đóng gói như cân, mạch điện, hình học cho phép sửa phần nội dung chữ, vẫn giữ cấu hình tương tác và bộ chấm đã kiểm chứng. Gemini không tạo hay thực thi một engine tùy ý; kiểu tương tác mới cần bổ sung renderer và evaluator vào ứng dụng.

## Đồng bộ và tương thích

- Mobile 1.3.3 đọc bài mới từ catalog máy chủ, nhận invalidation qua private Broadcast `matlingo:catalog`, và kiểm tra định kỳ mỗi 30 giây khi app hoạt động. Cần mạng, đăng nhập và hồ sơ được mở. Đây không phải cam kết cập nhật nền khi hệ điều hành đã dừng app.
- Catalog được lưu theo tài khoản. Phiên học lưu catalog/phiên bản đã bắt đầu để đáp án không đổi khi admin phát hành bản sửa. Khôi phục backup giữ snapshot bài học.
- Mỗi lần sửa bài lựa chọn tạo một `activity_version` và `content_release` mới. Bản phát hành cũ không bị sửa/xóa. Nội dung chữ của mô phỏng gốc được phủ qua `lesson_edits`; cấu hình chấm gốc không đổi.
- Mobile cũ 1.3.2 tiếp tục dùng release tương thích. Cần cài bản 1.3.3+7 để nhận bài tạo từ admin. Một chủ đề rỗng hoặc nháp không mở được phiên học mới.
- Chấm bài lựa chọn mới qua RPC `authored_attempt`, dùng đáp án phía máy chủ, kiểm tra chủ sở hữu/phiên bản và ghi nhận bằng luồng canonical hiện có. Flutter không ghi số dư hay điểm xác nhận.

## Gemini và quyền truy cập

`author-lesson` sử dụng cùng project secret **GEMINI_API_KEY** và **GEMINI_MODEL** với `tutor-chat`. Không đưa khóa Google vào trình duyệt, APK hoặc cấu hình public. Không thay cấu hình chatbox của người dùng.

Function kiểm tra JWT qua Auth và quyền admin đang hoạt động qua `get_my_access` trước khi gọi Google. Đầu ra JSON bị giới hạn vào schema của mẫu được hỗ trợ, được kiểm tra lại ở máy chủ; code, ID, quyền hoặc lệnh xuất bản do mô hình sinh không được sử dụng. Có giới hạn 4 lần/phút/admin trong mỗi isolate; đây không phải quota phân tán. Hai chức năng dùng chung quota của khóa Google hiện tại.

## Kiểm thử và chạy lại

Từ thư mục repository:

```powershell
flutter analyze
flutter test --no-pub --reporter expanded
& .\tools\run_admin_headless.ps1
```

Runner tự dùng cặp Chrome/ChromeDriver đã chuẩn bị bởi `prepare_headed_browser.ps1`, chạy Chrome **headless**, ghi log và kết quả trong `build/admin-headless-<timestamp>/`, rồi dọn driver của lượt chạy. Browser test dùng repository mô phỏng chung giữa admin và mobile; không cần tài khoản thật và không gọi Gemini có tính phí.

```powershell
& .\build\headed-tools\node_modules\deno\deno.exe test .\supabase\tests\author_handler_test.ts
```

`supabase/tests/admin_content_smoke.sql`, `admin_dashboard_smoke.sql` và `catalog_visibility_smoke.sql` kiểm tra cơ sở dữ liệu thật trong transaction rồi **ROLLBACK**. Không chạy file reset schema. Bộ mới bao phủ CRUD, catalog người học, client cũ, phiên bản đã ghim, chấm sai/đúng, XP canonical, retry, revision conflict, giả mạo kết quả, cách ly tài khoản, quyền admin và RLS.

Lượt xác minh 07/11/2026 đã gọi Gemini thật bằng tài khoản admin tạm, tạo bài pizza và chạy bản nháp đó qua kiểm thử phát hành/catalog/chấm điểm ở database trong transaction hoàn tác. Tài khoản tạm đã xóa và kiểm tra còn 0 bản ghi. Browser test dùng mô phỏng; chưa có một lượt browser-to-live-backend xuyên suốt bằng tài khoản thật, chưa xác minh trên điện thoại vật lý.

Ảnh dựng từ bản nháp thật: `build/admin-content-editor.png`, `build/admin-content-mobile.png`. Kết quả AI không chứa credential: `build/admin-gemini-live.json`. Bộ dựng ảnh dùng fallback deterministic khi không có bản nháp local này.

## Các phần thay đổi

- Admin UI: `lib/features/admin/admin_app.dart`, `admin_lesson_editor.dart`; state/repository: `admin_dashboard_controller.dart`, `admin_repository.dart`.
- Mobile: `authored_lesson.dart`, `mobile_catalog.dart`, `learning_catalog.dart`, `learning_store.dart`, `learning_journal.dart`, `learning_sync_controller.dart`, `learning_repository.dart`, `journey_app.dart`, `reasoning_workspace.dart`.
- Backend additive: migrations `20261110000000_admin_lesson_authoring.sql`, `20261111000000_authored_choice_validation.sql`; function `supabase/functions/author-lesson/`.
- Tests: `test/admin_content_test.dart`, `admin_content_preview_test.dart`, `admin_headless_smoke.dart`; `supabase/tests/author_handler_test.ts`, `admin_content_smoke.sql`; cập nhật số trigger mong đợi trong `admin_dashboard_smoke.sql` và thêm kiểm tra author function vào CI.

Không có service role key hay Google API key được thêm vào mã nguồn. Không sửa migration cũ hoặc xóa dữ liệu học hiện có. Kiểm tra security advisors không có finding mới cho các bảng/RPC này; các informational private deny-all RLS và cảnh báo leaked-password protection là cấu hình đã có, không được thay đổi trong công việc này.


## Icon bài học trong Studio (1.3.8+12)

Trong bảng Thuộc tính, mở **Chọn icon bài học**. Có 24 icon có nhãn, tìm không dấu, xem trước và trạng thái đang chọn; nút **Tự động theo engine** bỏ lựa chọn riêng. Sau khi chọn, bấm **Lưu nháp** hoặc **Phát hành**. Icon hiện trên thẻ bài trong thư viện Admin, mô phỏng điện thoại và checkpoint/đầu bài trên mobile. Bài chưa chọn riêng tự dùng icon theo engine đầu tiên có tương tác.

Mã icon nằm ở `config.lesson_icon` trong JSON đã có, đi cùng nháp, undo/redo, bản sao và phiên bản bài đã phát hành. Không thay schema, không sửa nội dung hoặc tiến độ đã có. CMS dùng Lucide hiện có, mobile dùng danh sách Material Icons cố định; mã không nhận diện được dùng icon tự động. Không cần tải ảnh, không thêm thư viện hay quyền thiết bị.

App có mạng tự đồng bộ danh mục khi phát hành; có Realtime và kiểm tra lại định kỳ 30 giây. Bản nháp không hiện trên app. Máy offline tải lại khi kết nối; phiên học đang mở giữ phiên bản đã ghim. Bài dùng các engine/icon đã có trong app không đòi hỏi APK mới. Khi thêm loại engine hoặc icon chưa được đóng gói trên mobile, phải cập nhật app; lần bổ sung bộ icon này cần 1.3.8+12.
