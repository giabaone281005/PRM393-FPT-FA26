# Supabase / Matlingo Admin Studio — 2026-11-10

Project `seoswmcldwwytdrfrrrb` đã có đầy đủ chín migration CMS mới, từ `admin_lesson_authoring` đến `studio_language_engines`. Đối chiếu trực tiếp cho thấy body của 26 hàm SQL runtime trùng với định nghĩa mới nhất trong source; cả bốn tệp của Edge Function `author-lesson` v2 cũng trùng. Không có thay đổi schema hoặc function còn chờ triển khai, nên lần kiểm tra này không chạy lại DDL, reset hay thay lịch sử migration.

`supabase/studio_deployment_manifest.json` ghi ánh xạ tên/timestamp local và remote, checksum UTF-8/LF của source migration, danh sách hàm đã so khớp và tệp Edge. Timestamp local khác remote là lịch sử có sẵn; manifest phục vụ đối chiếu, không phải lệnh deploy. Giữ nguyên migration cũ và không chạy `db push/reset` trên lịch sử được lưu này.

Danh mục tại thời điểm chụp có **4 chủ đề / 12 bài / 72 phần**, gồm bộ Toán, Tiếng Anh, Lập trình và chủ đề **Hình Học 3D** với hai bài mới tạo trong Admin. Nội dung đã phát hành được lưu tại `supabase/content/published_catalog_20261110.json`; đây là snapshot đọc, không tự ghi lại dữ liệu. Không xuất tài khoản, JWT, nhật ký, tiến độ hay ID người tạo vào snapshot. Test mobile xác nhận đọc được mọi chủ đề/bài trong snapshot, bao gồm ID mới tạo động. Không chạy lại script thay danh mục 3 chủ đề vì thao tác đó không áp dụng cho trạng thái đã có nội dung mới.

Kiểm tra hosted bằng `studio_sync_smoke.sql` đã qua: tạo ba bài qua RPC Admin, đủ 33 engine, ba icon, retry lưu nháp/phát hành/hoàn thành, lọc phiên bản app, chấm cả bài chưa hoàn thành và đáp án đúng, xác nhận 30 XP, từ chối người học phát hành hoặc ghi trực tiếp bảng nháp. Tất cả nằm trong transaction rollback. Truy vấn sau test xác nhận không còn tài khoản/chủ đề QA, vẫn 4 chủ đề và 12 bài hoạt động.

Để tái tạo kiểm tra, chạy `python tools/prepare_studio_sync_smoke.py`, duyệt SQL ở `build/studio-sync-smoke.sql`, rồi chạy qua kết nối quản trị của đúng project. Script chỉ tạo file SQL; không tự kết nối hoặc triển khai.

Kiểm thử local: Flutter analyze không lỗi; 325 unit/widget tests và một test snapshot mới; 76 CMS tests sau `npm ci`; TypeScript/Vite build; 33 Edge tests với Deno check/lint; 1.577 expanded + 729 legacy parity; các bộ standalone 50 / 2.491 / 17.552. APK debug có cloud config và Flutter web launcher đều build thành công; headed-runner host smoke xác nhận điều phối và xử lý lỗi bằng toolchain giả lập. Kiểm tra format/diff và quét credential trước commit không phát hiện secret.

Security advisors không có lỗi mới; 8 bảng private vẫn dùng RLS deny-all theo thiết kế, không có `SECURITY DEFINER` công khai. Cảnh báo Auth leaked-password protection tắt đã tồn tại từ trước ([hướng dẫn](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection)); lần này không thay cấu hình Auth. Kiểm thử giao diện Chrome bằng Computer Use vẫn chưa thực hiện vì host điều khiển không kết nối được; kết quả RPC/handler không được coi là kiểm thử UI.
