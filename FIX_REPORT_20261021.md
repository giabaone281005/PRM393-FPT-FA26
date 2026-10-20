# Sửa lỗi sau audit — 21/10/2026

**Mã nguồn đã sửa và kiểm thử tại workspace. Phần database/Edge Function chưa áp dụng lên Supabase.** Không kết luận toàn bộ dự án đã hết lỗi hoặc thanh toán thật đã nghiệm thu.

## Các lỗi đã sửa trong mã nguồn

| Vấn đề | Thay đổi | Bằng chứng |
|---|---|---|
| Dùng lại đáp án/request cũ sau mất mạng | Xác nhận đúng request đã đồng bộ; tuần tự hóa gửi đáp án và heartbeat; xóa pending cả khi trả lời sai mà câu hỏi không đổi | Regression localhost chạy đáp án sai → đồng bộ nền → đáp án đúng → câu tiếp theo → hoàn thành |
| Tiến độ giữ dữ liệu bé trước | Theo dõi ID bé, reload khi widget đổi ID; chặn response cũ ghi đè response mới | Hai widget test đổi bé và response về ngược thứ tự đạt |
| Thông báo lỗi không biến mất khi tải lại | Xóa lỗi cũ khi bắt đầu tải lại CMS và tủ đồ | Analyze/toàn bộ Flutter tests đạt; chưa chạy device E2E riêng hai màn |
| Home/header/map tràn ở màn hẹp/chữ lớn | Header đổi bố cục khi cần; nhãn và phần thưởng xuống dòng; nút học giãn chiều cao | Home/map/profile đạt ở 320×700, text scale 1.8, theme sáng |
| Gợi ý mua chưa theo tài khoản | Dựa trên đơn pending thật, trial đã dùng/chưa dùng và Plus đang hiệu lực/không thời hạn; chặn tạo lượt mua mới khi còn đơn pending | Ba test quy tắc tài khoản đạt; không gán ngẫu nhiên gói tháng/năm |
| Có thể chọn nhầm cổng khi tiếp tục đơn | Đọc cổng đã lưu và dùng lại; đối soát MoMo/VNPay theo cổng | Backend tests routing và provider guard đạt bằng mocks |
| Demo có thể cấp quyền mua thật | Bỏ lựa chọn demo, chặn gọi từ repository; mã endpoint demo mới luôn từ chối và không gọi settlement | Flutter và Node tests xác nhận không gọi gateway/settlement |
| Thông tin ví bị hiểu là đã xác minh | Nêu rõ chỉ lưu thông tin, chưa xác minh sở hữu và không tự trừ tiền | Thay nhãn và mô tả; không giả lập OTP hoặc liên kết provider |

Các thay đổi học tập nằm ở [study_repository.dart](D:/DEMO/PRM391/lib/data/repositories/study_repository.dart), [study_screen.dart](D:/DEMO/PRM391/lib/features/learning_engine/study_screen.dart), [learning_progress_screen.dart](D:/DEMO/PRM391/lib/features/learning_engine/screens/learning_progress_screen.dart), [content_management_screen.dart](D:/DEMO/PRM391/lib/features/admin/content_management_screen.dart), [mascot_wardrobe_screen.dart](D:/DEMO/PRM391/lib/features/mascot_wardrobe/screens/mascot_wardrobe_screen.dart).

Bố cục được sửa tại [home_screen.dart](D:/DEMO/PRM391/lib/features/home/screens/home_screen.dart), [app_header.dart](D:/DEMO/PRM391/lib/features/shared/widgets/app_header.dart), [treasure_map_screen.dart](D:/DEMO/PRM391/lib/features/treasure_map/screens/treasure_map_screen.dart).

Luồng mua được sửa tại [commerce_repository.dart](D:/DEMO/PRM391/lib/data/repositories/commerce_repository.dart), [purchase_guidance.dart](D:/DEMO/PRM391/lib/data/models/purchase_guidance.dart), [learning_packages_screen.dart](D:/DEMO/PRM391/lib/features/subscriptions/learning_packages_screen.dart).

## Bản sửa backend đã chuẩn bị, chưa chạy trên Cloud

Migration mới [20261026000000_payment_retention_and_attempts.sql](D:/DEMO/PRM391/supabase/migrations/20261026000000_payment_retention_and_attempts.sql):

- Đổi API discard/purge cũ sang kết thúc trạng thái chờ/hết hạn, giữ đơn và bằng chứng thanh toán. Callback hợp lệ đến muộn vẫn có đơn để xử lý.
- Lưu một checkout attempt cho mỗi đơn, cố định provider/environment và mã giao dịch đối tác; client chỉ đọc dữ liệu gia đình mình, không tự sửa lượt thanh toán.
- Cùng transaction MoMo được xử lý idempotent. Transaction thành công khác mã trên đơn đã trả tiền được ghi `REVIEW_DUPLICATE` và `PAYMENT_REVIEW`, không cấp thêm kỳ Plus.
- Từ chối settlement khác provider đã gắn với đơn. Các đơn cũ chưa có metadata không bị gán provider theo suy đoán.
- Không xóa đơn, payment, support link hoặc migration cũ; không thu hồi hai quyền mua đang có trên Cloud.

Sáu Edge Functions cần triển khai cùng bản schema:

1. [momo-checkout](D:/DEMO/PRM391/supabase/functions/momo-checkout/index.ts): dùng lại request/order ID và checkout đã lưu; không tạo hậu tố timestamp khi retry.
2. [momo-ipn](D:/DEMO/PRM391/supabase/functions/momo-ipn/index.ts): kiểm tra chữ ký/cổng/mã lượt và nhận diện kết quả cần đối soát.
3. [momo-query](D:/DEMO/PRM391/supabase/functions/momo-query/index.ts): đối soát đúng lượt MoMo, kiểm tra tương quan request/order/merchant và số tiền; kết quả chưa rõ không kích hoạt Plus.
4. [vnpay-checkout](D:/DEMO/PRM391/supabase/functions/vnpay-checkout/index.ts): gắn cổng và môi trường trước checkout.
5. [commerce-reconcile](D:/DEMO/PRM391/supabase/functions/commerce-reconcile/index.ts): chọn hàm query theo cổng đã lưu.
6. [demo-pay](D:/DEMO/PRM391/supabase/functions/demo-pay/index.ts): từ chối mô phỏng cấp quyền, kể cả nếu biến môi trường demo cũ đang bật.

Cách dùng requestId và API query đối chiếu [MoMo idempotency](https://developers.momo.vn/v3/vi/docs/payment/api/result-handling/idempotency/) và [MoMo query](https://developers.momo.vn/v3/docs/payment/api/payment-api/query/). Query dựa vào HTTPS đến endpoint được cho phép và kiểm tra tương quan phản hồi; không tự đặt ra một chữ ký phản hồi mà API không công bố.

Regression SQL [payment_safety_regression.sql](D:/DEMO/PRM391/supabase/tests/payment_safety_regression.sql) đã chuẩn bị: giữ đơn/bằng chứng, callback muộn, cache checkout, chống đổi provider, chống cấp Plus lặp, ghi giao dịch thêm và RLS gia đình khác. Tất cả fixture nằm trong transaction rollback. **Chưa chạy bằng PostgreSQL nên chưa xác nhận cú pháp PL/pgSQL, idempotency DDL hoặc RLS runtime.**

## Kiểm tra thực sự đã chạy

| Kiểm tra | Kết quả |
|---|---|
| `flutter analyze --no-pub` | Sạch, không lỗi/cảnh báo |
| `flutter test --no-pub --reporter expanded` | 249 đạt; 1 test localhost bỏ qua trong lượt mặc định |
| Test localhost chạy riêng với cấu hình chỉ trỏ `127.0.0.1:49477` | 1 đạt; không gọi merchant thật |
| `node --test test_backend/*.test.mjs` | 33 đạt, có 11 ca mới cho MoMo/demo/routing |
| `node scripts/check-sql.mjs` | 32 file đạt cấu trúc; không thay thế chạy PostgreSQL |
| Android debug với config hiện có | Build thành công |
| `git diff --check` | Đạt |

Test localhost đã được thêm vào [verify.yml](D:/DEMO/PRM391/.github/workflows/verify.yml) bằng bước riêng. SQL regression mới được thêm vào [test-sql.ps1](D:/DEMO/PRM391/scripts/test-sql.ps1).

APK: [app-debug.apk](D:/DEMO/PRM391/build/app/outputs/flutter-apk/app-debug.apk). Lượt này chỉ build, chưa cài/chạy APK trên thiết bị. Không chạy giao dịch thu tiền thật hoặc E2E merchant.

Log tại thư mục build: `D:/DEMO/PRM391/build/fix-analyze.log`, `D:/DEMO/PRM391/build/fix-all-flutter-tests.log`, `D:/DEMO/PRM391/build/fix-offline-tests.log`, `D:/DEMO/PRM391/build/fix-backend-tests.log`, `D:/DEMO/PRM391/build/fix-apk-build.log`.

## Điểm dừng và bước tiếp theo

Cơ chế duyệt tự động từ chối hai lần áp dụng migration lên `seoswmcldwwytdrfrrrb`, kể cả sau khi đối chiếu xác nhận cũ trong chat “Merge main vào nhánh hiện tại”. Lý do trả về: ngữ cảnh hiện tại chưa có xác nhận trực tiếp đáng tin cậy cho lần ghi RPC/RLS/thanh toán này. Không thử áp dụng bằng SQL Editor, CLI hoặc đường vòng khác. Lượt sửa này chỉ đọc database; chưa áp dụng migration hoặc deploy hàm.

Cần người dùng xác nhận trực tiếp cho **migration mới và triển khai sáu Edge Functions trên Supabase phát triển**. Sau đó:

1. Kiểm tra lại trạng thái đơn trước rollout; lần đọc gần nhất chỉ có hai đơn paid. Nếu xuất hiện đơn cũ chưa rõ provider còn chờ thanh toán, phải đối soát trước khi gắn cổng mới để không bỏ callback cũ.
2. Áp dụng migration mới; chạy regression mới và các regression commerce/legacy liên quan với rollback, kiểm tra idempotency/RLS/advisors. Không replay hoặc sửa migration lịch sử theo suy đoán.
3. Triển khai sáu hàm, giữ cấu hình secrets hiện có, kiểm tra xác thực/parent gate và endpoint trước giao dịch thử. Không công bố app chỉ với schema hoặc hàm cập nhật một phần.
4. Kiểm tra luồng phụ huynh → tạo/lưu đơn → checkout → callback/query → quyền Plus → mở lại app trên môi trường thử.

Chưa giải quyết các hạng mục cần cấu hình bên ngoài: lịch chạy đối soát thực tế, khóa merchant/môi trường, xác minh ví với provider, ký release, SMTP/deep link và AI thật. Các cảnh báo hiệu năng cần đo đạc riêng; không tự xóa index/policy/dữ liệu. Không pull, push, tạo PR hay phát hành.
