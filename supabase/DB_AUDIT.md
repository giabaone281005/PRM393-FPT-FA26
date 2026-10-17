# Kiểm tra Supabase — 17/10/2026

Project app đang dùng: `seoswmcldwwytdrfrrrb`. Người dùng cho phép xóa dữ liệu thử nghiệm, yêu cầu giữ code app hiện tại, kiểm tra Auth và bảng không sử dụng.

## Bằng chứng đã kiểm tra

- Auth health trả HTTP 200; email/password được bật, đăng ký không bị tắt, yêu cầu xác minh email đang bật.
- Truy vấn REST `select=*&limit=0` nhận diện đủ 34 bảng public có trong migrations. Không đọc dữ liệu người dùng. HTTP 42501 của role anon không chứng minh app đã đăng nhập bị lỗi quyền.
- `lessons` trả HTTP 200 cho anon, trong khi migration 18 thu hồi SELECT của anon. Cần kiểm tra grants thực tế, gồm quyền từng cột, và migration history; không coi các file trong repo là bằng chứng đã được triển khai.
- Không có kết nối quản trị/MCP trong phiên tại thời điểm kiểm tra. Chưa đọc log Auth, chưa chạy SQL Cloud, chưa xóa hoặc sửa dữ liệu.

## Vấn đề thấy trong mã DB

1. Migration 21 thêm `parents_auth_user_fk` tới `auth.users` với hành vi mặc định `NO ACTION`. Nếu Cloud có ràng buộc này và parent còn tồn tại, xóa Auth user sẽ bị chặn.
2. `subscriptions.upgraded_by` và `subscription_logs.performed_by` cũng tham chiếu Auth user mà không có `ON DELETE SET NULL`. Có thể chặn xóa tài khoản từng thực hiện thao tác.
3. Không chỉ thêm CASCADE ở parents: đơn, kỳ gói, support và AI còn tham chiếu parents/kids với NO ACTION. Cần quyết định cách xóa dữ liệu thử nghiệm hoặc giữ lịch sử tài chính trước khi thay ràng buộc.
4. Trigger `on_auth_user_created` gọi `public.handle_new_user` để insert parents. Cần kiểm tra thân hàm, owner, search_path, NOT NULL/DEFAULT và các trigger khác trên Cloud để xác định lỗi đăng ký; chưa có bằng chứng trigger này đang lỗi.
5. SMTP, redirect allowlist và trạng thái user/email confirmation có thể gây lỗi đăng ký/quên mật khẩu/đăng nhập. Không thể kiểm tra cấu hình SMTP riêng tư bằng endpoint settings công khai.
6. `supabase/seed.sql` chèn trực tiếp Auth users bằng chuỗi bcrypt mẫu, PIN mặc định và admin demo. Không dùng file này để tái dựng tài khoản đăng nhập thật. Migration curriculum 15 là nguồn bài học riêng.
7. Các migration 18–21 không được thiết kế để chạy lại trên schema đã có. Lỗi relation already exists không phải lý do tự động xóa DB.

## Bảng cần giữ theo luồng app/backend hiện tại

| Phân hệ | Bảng |
|---|---|
| Gia đình, phân quyền, PIN | parents, kid_profiles, user_roles, private.parent_unlocks |
| Nội dung, CMS | topics, lessons, questions, skills, lesson_drafts, lesson_versions |
| Phiên học, báo cáo, thưởng | study_sessions, question_attempts, kid_progress, kid_streaks, practice_garden_logs, study_daily_usage, private.session_payloads |
| Tủ đồ | mascot_items, kid_inventory, kid_equipment |
| Đấu trường | tournaments, tournament_members |
| Gói học, VNPay, hoàn tiền | subscriptions, subscription_logs, learning_plans, plan_prices, learning_orders, learning_payments, payment_events, subscription_periods, refund_requests |
| Quản trị, hỗ trợ, thông báo | admin_audit_logs, support_requests, notifications |
| AI | ai_settings, private.ai_requests |

Các bảng được gọi gián tiếp qua RPC/trigger/Edge Functions vẫn đang sử dụng dù Flutter không gọi `.from()` trực tiếp.

## Thành phần legacy cần đối chiếu

- `admins`: dùng khi migration 18 chuyển admin cũ sang user_roles. Runtime mới xác thực admin bằng user_roles; giữ đến khi xác nhận chuyển quyền và bỏ phụ thuộc migration/bootstrap cũ.
- `orders`, `payments`: không phải bảng VNPay mới. RPC `private.legacy_commerce_history` vẫn đọc nếu tồn tại để admin tra cứu lịch sử. Có thể loại khỏi bản dựng mới nếu dữ liệu thử nghiệm được bỏ; không đổi tên thành learning_orders/learning_payments.
- `subscription_plans`: không nằm trong bộ 34 bảng repo tạo; cần snapshot để kiểm tra phụ thuộc của bảng legacy trước khi bỏ.
- View `v_leaderboard`: còn được migration 20 tham chiếu để thu hồi quyền. App dùng RPC get_arena_board. Chỉ xóa sau khi đối chiếu phụ thuộc.
- Không xóa schema hệ thống auth/storage/realtime/extensions hoặc bảng migration history để chữa lỗi app.

## Bước tiếp theo

Kết nối Supabase MCP theo lựa chọn của người dùng. Nếu cần SQL Editor, chạy `supabase/tests/full_schema_auth_audit.sql`: chỉ đọc metadata, dùng được cả khi thiếu migration. Kết quả chứa định nghĩa trigger; không chia sẻ công khai nếu trigger tùy chỉnh chứa secret.

Sau khi có quyền quản trị: lấy Auth logs và cấu hình, xác nhận migration/schema drift, chọn sửa tại chỗ hoặc dựng lại schema app từ migrations trên môi trường thử nghiệm, kiểm thử Auth đăng ký → xác minh → đăng nhập → đăng xuất → khôi phục mật khẩu → xóa user. Chưa khẳng định hoàn tất hoặc chữa được lỗi Cloud trước khi thực thi và xác minh các bước này.
