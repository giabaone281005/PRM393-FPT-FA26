# Kết quả kiểm tra — 18/10/2026

Kết quả mới nhất: analyze đạt; **212 Flutter tests**, **22 backend tests** và **25 file SQL** đạt kiểm tra cấu trúc. Năm bộ SQL hiện có (commerce, role/learning, session time, content/payment và legacy compatibility) đã chạy lại trên Cloud, đạt và rollback fixture. Phiên QA online ghi thêm 122 giây, khớp session và usage. APK debug mới build/cài/khởi động trên Pixel 9 thành công. Migration `20261024000000_cloud_wrong_answer_reviews.sql` đã áp dụng; runtime regression mới đạt/rollback, HTTP QA Basic/Plus đọc đúng 6/0 câu sai và từ chối gia đình khác. Idempotency RPC đạt; lần thử apply lại DDL bị lỗi requestState, chưa được coi là đạt. Sau xác nhận riêng, cả ba Edge Functions đã deploy ACTIVE: ai-tutor v1, vnpay-refund v1, commerce-reconcile v2. Smoke HTTP đạt: refund từ chối phụ huynh 403, job thiếu/sai khóa 401, AI chưa cấu hình trả 503. AI vẫn tắt, chưa có cron hoặc yêu cầu AI/hoàn tiền. Release vẫn thiếu cấu hình ký; SMTP/deep link, merchant/AI thật và iOS chưa nghiệm thu. Xem [bằng chứng và giới hạn đầy đủ](supabase/AUDIT_20261018.md).

## Kết quả lịch sử — 16/10/2026

| Kiểm tra đã chạy tại workspace | Kết quả |
|---|---|
| Flutter analyze | Không có lỗi/cảnh báo |
| Flutter tests | 17 đạt |
| Node backend tests | 21 đạt |
| Kiểm tra cấu trúc SQL và signatures/grants/wrappers | 13 file đạt kiểm tra tĩnh |
| Android debug với config/app.json | Build thành công |

APK: `build/app/outputs/flutter-apk/app-debug.apk`.

Đã kiểm tra thêm kết nối công khai từ máy tới `api.supabase.com/v1/projects`: API phản hồi 401 khi không gửi token, cho thấy kết nối tới endpoint hoạt động tại thời điểm kiểm tra. Không dùng token và không gọi SQL trên Cloud.

**Chưa thực hiện:** chạy migrations/regression SQL trên database, Supabase Edge/Deno runtime thật, giao dịch merchant VNPay/Gemini thật, kiểm thử thiết bị iOS và build có chữ ký production. Người dùng lựa chọn chỉ tạo script SQL, không tải PostgreSQL nhúng. Kiểm tra tĩnh và Node mocks không thay thế các bước đó.

Người dùng gửi ảnh `42P07 relation orders already exists`, kết quả 4 mốc false và JSON schema. Snapshot xác nhận `orders`/`payments` legacy khác cấu trúc mới (`orders.order_code/plan_id`, `payments.order_id text`, provider MoMo/ZaloPay). Migrations pending, app và backend đã đổi sang `learning_orders`/`learning_payments`, giữ nguyên các bảng legacy. Admin có tra cứu lịch sử cũ; script `legacy_commerce_compatibility.sql` kiểm tra cấu trúc/FK còn nguyên sau triển khai. Chưa thực thi SQL trên Cloud; lấy lại các file mới nhất và chạy 18 → 19 → 20 → 21 theo hướng dẫn.

Xem thứ tự triển khai, cấu hình và nghiệm thu trong [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).

Sửa lỗi fixture `23505 parents_pkey` trong cả ba script regression: trigger `on_auth_user_created` của migration 14 tự tạo parent khi insert auth user; bước tạo parent bổ sung nay dùng `ON CONFLICT (id) DO NOTHING`. Không thay đổi migrations/dữ liệu ứng dụng. Chỉ kiểm tra cấu trúc SQL tại workspace; chưa chạy lại regression trên database.
