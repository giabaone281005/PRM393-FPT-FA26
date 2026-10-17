# Đối chiếu kế hoạch và mã triển khai

Đọc cùng [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md). “Đã triển khai” dưới đây nói về mã và hợp đồng dữ liệu; không có nghĩa đã chạy SQL trên Supabase hoặc nghiệm thu merchant thật.

Đã xử lý xung đột với schema Cloud được cung cấp: đơn/payment mới dùng `learning_orders`/`learning_payments`. Hai bảng `orders`/`payments` cũ và `subscription_plans` được giữ nguyên; admin có tra cứu lịch sử legacy trong chi tiết gia đình. Không tự nhập các giao dịch cũ thành payment đã xác minh.

| Hạng mục kế hoạch | Mã/hợp đồng đã triển khai | Trước phát hành |
|---|---|---|
| Auth thật, bỏ demo/OTP local | AuthRepository, AuthScreen, AccountScreen, deep link Android/iOS; bỏ widget OTP giả | SMTP, email xác minh/recovery trên thiết bị |
| PIN và thao tác nhạy cảm | PIN băm, rate limit, token gắn session, gate khi chạy nền; RPC hồ sơ/giới hạn/order/support | Regression SQL, kiểm tra lifecycle thực tế |
| Hồ sơ và quyền sau hết Plus | Archive/restore, giữ thành tích, active_kid_id Basic, tối đa 3 Plus; chọn/lưu bé hiện tại | Kiểm thử gia đình đang có nhiều bé |
| Báo cáo thật | family_report: 7 ngày, phiên gần nhất, skills/accuracy và gợi ý ôn | Cần dữ liệu học thật để đánh giá chất lượng gợi ý |
| Gói, đơn, mua/khôi phục | Catalog draft, month/year, snapshots, UUID idempotency, lịch sử, resume pending, querydr | Điền giá, merchant sandbox/production |
| Quyền Plus | Settlement nguyên tử, payment/event unique, subscription periods; kiểm tra quyền mỗi RPC | Migration và SQL test staging |
| Refund/reconcile | Full refund HMAC, claim chống gửi lặp, trạng thái unknown, truy vấn refund, revoke đúng kỳ, job | Cron/Vault, xác nhận IP/provider policy |
| Hỗ trợ và thông báo | Ticket gắn đơn, phản hồi admin, thông báo purchase/refund/expiry/support, read state | Quy trình nhân sự tiếp nhận hỗ trợ |
| Phiên học và thưởng | Private payload snapshot, giá trị đáp án + question ID, accuracy/heart/session thật; thưởng lần đầu | Regression SQL, các tình huống đồng thời/thiết bị |
| Tự luận | Cách giải + đáp số được biên tập, kiểm tra server | Chưa tự động chấm chất lượng lập luận tự do |
| Thời gian/streak | Heartbeat foreground, budget ngày Việt Nam, nghỉ 10 phút, streak server trước 21h | Mất mạng/background/midnight trên thiết bị; offline duration không được xác nhận đầy đủ |
| Hồi tim | 5 câu đúng, một log/session, không farm sao | SQL regression |
| Đấu trường | Nhóm 30 cùng lớp, ISO week-year, điểm từ session, tối đa 5 lượt/ngày, tuần trước | Chạy dữ liệu nhiều nhóm trên staging |
| Tủ đồ | Catalog, preview, owned/equipped, server price, mua nguyên tử, trang bị lại miễn phí | Thử nhiều thiết bị cùng mua |
| CMS/moderator | Topic, drafts, 5 payload templates, preview, validation, publish/hide, immutable question rows và versions | Biên tập viên duyệt nội dung seed lặp trước mở bán |
| AI | Ảnh thật, OCR, sửa đề, gợi ý từng bước; quota/rate/idempotency backend, không lưu ảnh | Key/model, chính sách dữ liệu provider, kiểm thử chất lượng; mặc định tắt |
| Mạng chập chờn | Cache theo tài khoản/bé đến 15 phút, outbox một đáp án, retry UUID, không cấp thưởng offline | Không phải bộ Plus tải xuống hoàn toàn |
| Admin vận hành | Dashboard server, debounce/phân trang, chi tiết gia đình, giá phiên bản, hỗ trợ, cấp bù, roles và audit | Bootstrap UID admin và phân công vận hành |
| Database | Giữ 19 bảng cũ; thêm commerce, usage, CMS, audit/notifications, refund, AI, support; private payload/token/AI requests | FK Auth NOT VALID giữ seed mồ côi; rà soát rồi validate |
| QA và phát hành | Flutter/Node tests, SQL regression scripts, kiểm tra cấu trúc SQL, CI, cấu hình theo môi trường, release key guard | SQL runtime, VNPay/Gemini thật, iOS, chữ ký production chưa được kiểm chứng trong phiên này |

Các lựa chọn theo kênh: VNPay không tự gia hạn nên không có màn hủy tự gia hạn/store acknowledgement; trial chưa có chính sách nên không tự thêm. Giá và quota do admin cấu hình. Không quảng bá chức năng chưa bật.

Migrations mới chưa áp dụng: `20261018000000_family_commerce_vnpay.sql`, `20261019000000_verified_learning_sessions.sql`, `20261020000000_economy_content_operations.sql`, `20261021000000_payment_ai_operations.sql`.

Script SQL: `preflight.sql`, `commerce_regression.sql`, `role_learning_regression.sql`, `content_payment_operations.sql`, `postflight.sql` trong `supabase/tests/`. Các script regression có ROLLBACK, không gọi dịch vụ bên ngoài.
