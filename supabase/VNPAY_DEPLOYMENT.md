# Triển khai VNPay và các phân hệ MathLingo

Hướng dẫn thống nhất đã chuyển sang [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md).

**Quan trọng:** áp dụng đủ bốn migrations mới `20261018 → 20261021` sau bốn migrations cũ đã chạy. Không chỉ chạy migration commerce đầu tiên, không chạy lại seed và không reset Cloud.

Bản mới dùng `learning_orders`/`learning_payments`, giữ nguyên `orders`/`payments` legacy. Lấy lại nội dung file migration 18 mới nhất nếu tab SQL cũ vẫn có `CREATE TABLE public.orders`.

Hướng dẫn bao gồm migration/test SQL, Auth/admin, secrets, bảy Edge Functions, VNPay IPN/query/refund, Cron/Vault, AI/quota, CMS, hỗ trợ, build Android và ký release. Chưa có migration hoặc function nào được triển khai lên Cloud trong phiên phát triển này.
