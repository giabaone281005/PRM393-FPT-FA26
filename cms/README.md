# Matlingo Admin

Admin Web/CMS mới dùng React, TypeScript và Vite, thay toàn bộ giao diện trước. Entry `lib/admin_main.dart` chuyển thẳng đến `/cms/`; không khởi chạy Flutter Admin cũ và không truyền token qua URL.

## Chạy

```powershell
cd cms
npm ci
npm run dev
```

Mở `http://127.0.0.1:8090/cms/`. Đăng nhập tài khoản Admin đang hoạt động, hoặc chọn **Mở sandbox trải nghiệm**. Sandbox không sửa dữ liệu thật, không gọi Gemini thật và không ghi XP.

Cấu hình public từ `.env.local` (`VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY`) hoặc hai trường tương ứng trong `../config/app.mobile.json`. Không dùng service-role hay Gemini key trong frontend.

## Luồng sử dụng

1. Dashboard có tổng quan, người dùng/tiến độ, chủ đề và **Studio soạn thảo**.
2. Tạo/chọn chủ đề, chọn **Tạo bài học** để nhận khung bốn bước phù hợp lĩnh vực.
3. Kéo engine từ palette vào flow canvas; bấm để thêm khi dùng cảm ứng/bàn phím. Có 33 engine, tìm kiếm, gợi ý từ khóa, sắp xếp, nhân bản, xóa, undo/redo.
4. Chọn slide và chỉnh Inspector: nội dung, tham số, đáp án, gợi ý, lời giải. Simulator bên phải đổi ngay và cho chơi thử theo cùng quy tắc chấm của mobile/backend.
5. Story nhận URL HTTPS hoặc upload/kéo thả ảnh tối đa 5 MB. SVG được làm sạch rồi chuyển PNG để tương thích mobile. Upload cloud dùng URL công khai ổn định trong bucket `lesson-assets`. Ảnh xem trước trong sandbox chỉ ở trình duyệt; không dùng data URL để phát hành thật.
6. Quality Guard kiểm tra tỷ lệ quiz và tương đồng trên 70% với bài đã phát hành cùng chủ đề. Các cảnh báo yêu cầu Admin xem xét, không tự chặn nội dung hợp lệ.
7. Trợ lý AI hỏi `tutor-chat` trong ngữ cảnh bài học, có duyệt trước khi chèn câu trả lời vào slide mới. Không tự áp dụng hay tự phát hành.
8. Tự lưu nháp theo tài khoản+bài; bản chờ retry giữ nguyên snapshot/operation ID. Phát hành có kiểm tra và xác nhận, tạo phiên bản mới, không ghi đè phiên học cũ. Có khôi phục sau reload và xuất JSON khi conflict.

Mobile cần **1.3.6+10** để dùng bộ engine mở rộng. Bản cũ tiếp tục nhận release phù hợp phiên bản của nó. Bài đóng gói cũ vẫn sửa được metadata và lưu trữ; tạo bài mới để thiết kế luồng tương tác mới.

## Backend

Dùng các API hiện có: `get_my_access`, `admin_dashboard_read`, `admin_learning_mutate`, `admin_content_read`, `admin_builder_read`, `admin_builder_save`, `admin_content_mutate`, `tutor-chat`. Migration mới `supabase/migrations/20261114000000_studio_tinkercad_v2.sql` mở rộng bộ chấm và thêm `admin_studio_progress`, bucket/RLS upload ảnh. Chỉ active Admin được truy cập; backend kiểm tra lại ở từng thao tác. Client không tính/ghi XP.

Đã áp dụng ba migration `studio_tinkercad_v2`, `admin_existing_lesson_editing`, `admin_metadata_compatibility` lên hosted ngày 2026-11-09. Không chạy lại toàn bộ lịch sử/reset. Ứng dụng mở trang Tổng quan; Studio là một chức năng trong Admin.

Chỉnh bài có sẵn: vào **Studio soạn thảo**, chọn chủ đề và bài, sửa nội dung ở Thuộc tính rồi **Phát hành**. Bài trắc nghiệm còn sửa được lựa chọn/lý do/đáp án; những bài gốc dùng bộ chấm đóng gói phải chọn rõ đáp án khi chuyển sang phiên bản biên soạn được. Các mô hình đóng gói khác chỉ sửa phần nội dung, giữ nguyên cấu hình chấm để bảo toàn lịch sử học.

## Kiểm thử / đóng gói

```powershell
npm test
npm run build
```

76 test CMS bao gồm bộ PostgreSQL trong bộ nhớ PGlite, không cần database bên ngoài. Fixture tại `../supabase/tests/fixtures/studio_engines.json` được dùng chung với test Flutter.

Từ root, chạy `tools/build_cms.ps1`. Output là `build/admin-web/cms/`, entry `build/admin-web/index.html` mở Studio mới. Có thể static serve toàn bộ `build/admin-web`. Nếu build lại Flutter web launcher vào cùng thư mục, chạy lại script CMS sau đó.

Simulator là mô phỏng web, không phải Android emulator. Các giới hạn preset, kiểm thử đã chạy và bước rollout còn lại: [báo cáo triển khai](../docs/CMS_TINKERCAD_IMPLEMENTATION.md).

## Mở rộng mobile 1.3.6

Kho hiện có 30 engine, thêm trục số, tô/so sánh phân số, nhập số, parabol, biểu đồ cột, tọa độ, Venn và nhận diện SVG. Native Flutter đã tích hợp fl_chart, flutter_svg, flutter_math_fork; phát hành mới yêu cầu mobile 1.3.6. Migration studio_mobile_engine_expansion đã áp dụng lên hosted.

Chủ đề đang mở có nút **Chỉnh sửa chủ đề đang chọn**. Với bài đóng gói cũ, mở bài rồi dùng **Soạn lại bằng Studio và thêm engine**, kiểm tra cấu hình/đáp án trước khi phát hành. Phiên bản cũ và lịch sử học được giữ nguyên. Báo cáo, thư viện, APK và kiểm thử: [Mobile engine expansion](../docs/MOBILE_ENGINE_EXPANSION.md).


## Đồng bộ 2026-11-10

Bộ 33 engine gồm nghe, nói và viết; bộ chọn icon bài có 24 lựa chọn tại Thuộc tính. Mobile 1.3.8+12 hỗ trợ icon và các chủ đề mới không thuộc nhóm cố định. Bản nháp chưa hiện cho người học; phát hành cập nhật danh mục qua Realtime và đồng bộ 30 giây. Danh mục hosted hiện có 4 chủ đề / 12 bài, gồm Hình Học 3D do Admin tạo. Xem `../docs/SUPABASE_STUDIO_SYNC_20261110.md` cho kiểm chứng và lịch sử triển khai.
