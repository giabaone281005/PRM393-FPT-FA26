# Kết quả kiểm tra — 16/10/2026

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
