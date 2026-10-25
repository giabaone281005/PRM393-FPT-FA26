# Hướng dẫn triển khai MathLingo

**Cập nhật 18/10/2026:** Cloud đã có các đối tượng từ migrations 18–23 và một số Edge Functions, nhưng lịch sử migration chưa đầy đủ. Không áp dụng lại nguyên các migration dưới đây lên project hiện tại trước khi đối chiếu định nghĩa. Xem [audit Cloud và kiểm thử mới nhất](supabase/AUDIT_20261018.md); hướng dẫn thứ tự bên dưới chỉ dùng sau khi xác định đúng trạng thái môi trường đích. Chưa nghiệm thu thanh toán/AI thật.

## 1. Phạm vi bản này

| Vai trò | Luồng đã có trong mã |
|---|---|
| Phụ huynh | Đăng ký/xác minh email, đăng nhập, khôi phục/đổi mật khẩu, PIN server, báo cáo thật, quản lý/lưu trữ/khôi phục bé, chọn bé Basic, giới hạn học, mua gói và lịch sử, thông báo, gửi yêu cầu hỗ trợ |
| Học sinh | Lộ trình theo bé/chủ đề, lý thuyết, 5 dạng tương tác, chấm server, tự luận có đáp số, lưu phiên dở, hồi tim qua 5 câu, thưởng một lần/bài, đấu trường nhóm 30, tủ đồ sở hữu/trang bị, ảnh OCR và gợi ý AI khi bật |
| Admin | Tổng quan, tìm kiếm/phân trang gia đình, cấp bù Plus có lý do, danh mục/phiên bản giá, đơn/đối soát/hoàn tiền toàn phần, xử lý hỗ trợ, phân quyền, hạn mức AI, nhật ký |
| Moderator | Chủ đề, nháp, xem trước, xuất bản/ẩn bài theo phiên bản. Không có quyền quản lý giao dịch, cấp gói hoặc role |

Kênh được chọn là **VNPay qua backend**, thanh toán từng kỳ tháng/năm, không tự gia hạn. MoMo, store billing, coupon/referral và offline Plus đầy đủ thuộc các hướng mở rộng trong kế hoạch, chưa được tích hợp ở bản VNPay này. Không có trial giả hoặc nút tự cấp Plus.

## 2. Chuẩn bị môi trường

- Flutter đã dùng để kiểm thử: **3.47.4**, Dart **3.13.3**; Node **24** để chạy kiểm thử handler TypeScript.
- Java/Android SDK theo Flutter; trên máy này APK debug đã build được. iOS cần macOS/Xcode để build và kiểm tra camera/deep link.
- Một Supabase staging và bản backup production trước khi thay schema/quyền.
- Merchant VNPay sandbox và thông tin kết nối do VNPay cấp. Giá thật do bạn quyết định, chưa có giá kinh doanh mặc định.
- AI tùy chọn: Gemini API key/model hỗ trợ ảnh và JSON Schema. Mặc định cấu hình database tắt AI, quota bằng 0.

Chạy tại thư mục gốc:

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
node --test test_backend/*.test.mjs
node scripts/check-sql.mjs
```

Nếu Windows báo thiếu hỗ trợ symlink khi thêm plugin, bật Developer Mode rồi chạy lại `flutter pub get`. Không cần cài PostgreSQL để chạy các kiểm thử Dart/Node. Kiểm tra cấu trúc SQL chỉ phát hiện lỗi dấu ngoặc/chuỗi; **không thay thế thực thi SQL**.

## 3. Migrations: chỉ chạy bốn file mới, theo thứ tự

**Cập nhật theo schema Cloud bạn đã gửi:** `public.orders` và `public.payments` là bảng thanh toán cũ, khác schema VNPay mới. Bản mã hiện tại dùng **`public.learning_orders` và `public.learning_payments`**. App, Edge Functions, khóa ngoại, RLS và script kiểm thử đã đồng bộ theo tên mới. Giữ nguyên hai bảng cũ cùng `subscription_plans`, dữ liệu và ràng buộc của chúng; không đổi kiểu `payments.order_id` cũ từ text sang UUID.

Với kết quả cả 4 mốc false và snapshot này, hãy **mở lại file migration 18 mới nhất trong repository và sao chép lại toàn bộ**, rồi chạy 18 → 19 → 20 → 21. Tab SQL Editor đã dán nội dung cũ vẫn có `CREATE TABLE public.orders` sẽ tiếp tục báo lỗi. Nếu session còn ở transaction lỗi, chạy `ROLLBACK;` trước. Không chạy chồng bản cũ và bản mới.

Thay đổi này dành cho trạng thái migration 18 chưa commit như snapshot đã cung cấp. Nếu môi trường khác từng chạy thành công bản commerce dùng `public.orders/public.payments`, cần đối chiếu riêng trước khi chuyển; không áp dụng quy trình này để tự động chuyển lịch sử đã xác minh.

Bạn xác nhận bốn migrations cũ đến `20261017000000_admin_and_subscriptions.sql` đã chạy. Không chạy lại seed, không dùng `db reset` trên Cloud.

1. `supabase/migrations/20261018000000_family_commerce_vnpay.sql`: vai trò UID, PIN băm, catalog, giá, đơn, thanh toán, kỳ quyền, khóa payload.
2. `supabase/migrations/20261019000000_verified_learning_sessions.sql`: quyền phụ huynh, archive/Basic active kid, phiên học/đáp án/chấm/thời gian/thưởng, curriculum metadata.
3. `supabase/migrations/20261020000000_economy_content_operations.sql`: inventory/equipment, nhóm đấu trường, skills/CMS/version, báo cáo, phân trang, audit/thông báo.
4. `supabase/migrations/20261021000000_payment_ai_operations.sql`: refund, quyền sau hoàn tiền, job đối soát/bảo trì, AI/quota, hỗ trợ, FK Auth và kiểm soát ghi trực tiếp.

**Chạy đủ cả bốn trước khi dùng app mới.** Chúng có transaction riêng. Nếu một file lỗi, dừng ở file đó; kiểm tra rollback rồi sửa nguyên nhân, không chạy tiếp các file phụ thuộc. App cũ ghi trực tiếp nhiều bảng sẽ không tương thích với quyền mới.

Trước khi chạy, dùng SQL Editor staging mở `supabase/tests/preflight.sql`. Kiểm tra `pgcrypto` ở schema `extensions`, cấu trúc thực tế khớp repository, danh sách admin và dữ liệu seed mồ côi. Nếu extension đang ở schema khác, điều chỉnh có chủ đích trước khi chạy migration; không tự tạo hai bản extension.

Có hai cách triển khai:

- SQL Editor: chạy nguyên từng file mới theo thứ tự trên, sau đó chạy các script kiểm thử staging.
- CLI: trước hết đối chiếu migration history. Nếu trước đây chạy SQL thủ công, ghi nhận **đúng bốn migration cũ** đã áp dụng bằng quy trình `migration repair --status applied` của CLI, chỉ sau khi xác nhận schema tương ứng; sau đó kiểm tra dry run để push đúng bốn file mới. Dùng `supabase migration --help`, `supabase db push --help` theo phiên bản CLI đang cài. Không repair một file mới chưa chạy thành applied.

Migration giữ dữ liệu/thành tích cũ. FK `parents → auth.users` được thêm `NOT VALID`: bảo vệ bản ghi mới, giữ các seed cũ mồ côi để bạn rà soát. Sau khi xử lý các bản ghi đó theo chính sách dữ liệu, mới chạy `ALTER TABLE public.parents VALIDATE CONSTRAINT parents_auth_user_fk;`. Không xóa gia đình thật để làm sạch fixture.

PIN mặc định cũ `1234` bị vô hiệu hóa; PIN hợp lệ khác được băm. Cần thiết lập PIN khi vào cổng phụ huynh. Token mở cổng chỉ nằm trong RAM, gắn với phiên đăng nhập và hết hạn 15 phút; app khóa khi chạy nền hoặc rời cổng. Mọi thao tác hồ sơ/giới hạn/mua/hỗ trợ cần token server xác minh.

## 4. Kiểm thử SQL sau migrations

Chạy độc lập từng file bằng SQL Editor staging với quyền quản trị:

```text
supabase/tests/commerce_regression.sql
supabase/tests/role_learning_regression.sql
supabase/tests/content_payment_operations.sql
supabase/tests/postflight.sql
```

Riêng Cloud có hai bảng cũ như snapshot, chạy thêm `supabase/tests/legacy_commerce_compatibility.sql` sau bốn migrations. Script chỉ đọc, kiểm tra bảng/ràng buộc cũ còn nguyên và các khóa ngoại mới trỏ vào `learning_orders/learning_payments`. Không chạy script riêng này trên staging mới không có các bảng legacy.

Ba script regression tạo fixture trong transaction và kết thúc bằng **ROLLBACK**. Không gọi mạng/VNPay/Gemini. Kiểm tra kết quả `... passed`; nếu có lỗi, rollback transaction rồi xử lý trước khi tiếp tục. `postflight.sql` chỉ đọc, trả danh sách cần rà soát.

Nếu bản script cũ báo `23505 parents_pkey` ngay sau khi tạo `auth.users`, trigger `on_auth_user_created` đã tự tạo phụ huynh. Các script mới dùng `ON CONFLICT (id) DO NOTHING` cho bước tạo phụ huynh. Chạy `ROLLBACK;` riêng, rồi sao chép và chạy lại **toàn bộ file kiểm thử mới nhất**. Không cần chạy lại migrations hay xóa phụ huynh.

Nếu đã tự cài psql, có thể cấu hình `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD` cho staging và chạy:

```powershell
./scripts/test-sql.ps1 -Staging
```

Script không tải PostgreSQL. Không đặt mật khẩu database vào Git. Các assertion kiểm tra RLS A/B, helper private, token PIN, đáp án/thưởng lặp, hồi tim, thời gian, inventory, moderator, phiên bản CMS và trạng thái hoàn tiền. **Các script này chưa được thực thi trong phiên phát triển này.**

Nếu SQL Editor báo `Failed to fetch (api.supabase.com)`, chưa thể kết luận SQL đã lỗi hay chưa chạy. Thử đăng nhập Dashboard trong cửa sổ ẩn danh, tắt tiện ích CORS/ad blocker cho site và kiểm tra mạng. Sau khi kết nối lại, chạy `supabase/tests/migration_state.sql` (chỉ đọc) để xem các mốc schema hiện diện trước khi chạy lại DDL. Nếu vẫn lỗi, ghi nhận mã HTTP/Console và file đang chạy; không reset database để xử lý lỗi kết nối Dashboard.

`postflight.sql` còn liệt kê câu hỏi thiếu đáp án và nội dung lặp của seed cũ. CMS giữ lịch sử thay vì xóa câu hỏi đã có attempts. Nội dung seed không được coi là đã duyệt sư phạm; cần biên tập viên duyệt trước khi mở bán rộng.

## 5. Supabase Auth và admin đầu tiên

Trong Dashboard Auth:

1. Bật xác minh email và cấu hình SMTP/URL gửi thư cho môi trường sử dụng.
2. Thêm redirect allowlist `mathlingo://auth-callback` cho bản mobile; cấu hình Site URL hợp lệ của bạn.
3. Tắt anonymous sign-in nếu không sử dụng; đặt chính sách mật khẩu phù hợp (app yêu cầu ít nhất 8 ký tự).
4. Thử link xác minh và quên mật khẩu ở cả trạng thái app đang mở và đã đóng.

Android/iOS đã đăng ký scheme trong manifest/plist. Khi nhận `passwordRecovery`, app mở màn đặt lại mật khẩu. Trường hợp không có cấu hình Supabase, app báo không kết nối, không đăng nhập bằng tài khoản demo.

Admin bootstrap: tạo tài khoản thật bằng Auth, xác minh email, lấy UID. Trong SQL Editor quản trị chạy một lần, thay UID:

```sql
INSERT INTO public.user_roles(user_id,role)
SELECT id,'admin' FROM auth.users
WHERE id='<UID_DA_XAC_MINH>'::uuid AND email_confirmed_at IS NOT NULL
ON CONFLICT(user_id,role) DO NOTHING;
```

Đăng nhập lại. Sau đó quản lý admin/moderator trong dashboard bằng UID và lý do. Không có tài khoản/mật khẩu admin cố định. Server ngăn thu hồi admin cuối cùng.

## 6. Secrets và deploy backend

Sao chép `supabase/.env.example` thành file riêng được Git bỏ qua. Điền:

| Secret | Mục đích |
|---|---|
| `VNPAY_TMN_CODE`, `VNPAY_HASH_SECRET` | Merchant sandbox/production tương ứng |
| `VNPAY_PAYMENT_URL`, `VNPAY_QUERY_URL` | Endpoint đúng môi trường, backend chỉ chấp nhận host/path VNPay đã định |
| `VNPAY_RETURN_URL` | `https://<ref>.supabase.co/functions/v1/vnpay-return` |
| `VNPAY_SERVER_IP` | IP server được VNPay chấp nhận cho query/refund |
| `COMMERCE_JOB_KEY` | Secret ngẫu nhiên ít nhất 32 byte cho job, không đưa vào Flutter |
| `GEMINI_API_KEY`, `GEMINI_MODEL` | Chỉ cần khi bật AI; model do bạn chọn và kiểm thử |

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` do môi trường Edge cung cấp. Không đưa service key, merchant secret hoặc AI key vào `config/app.json`.

```powershell
supabase secrets set --env-file supabase/.env.local --project-ref <ref>
supabase functions deploy vnpay-checkout --project-ref <ref>
supabase functions deploy vnpay-ipn --project-ref <ref>
supabase functions deploy vnpay-return --project-ref <ref>
supabase functions deploy vnpay-query --project-ref <ref>
supabase functions deploy vnpay-refund --project-ref <ref>
supabase functions deploy commerce-reconcile --project-ref <ref>
supabase functions deploy ai-tutor --project-ref <ref>
```

Các function dùng `verify_jwt=false` theo `supabase/config.toml`: checkout/query/refund/AI tự xác minh user với Auth, IPN xác minh HMAC, reconcile xác minh job key. Return chỉ hiển thị thông tin; không cấp Plus. Không triển khai function thiếu cơ chế xác minh này.

Đăng ký với VNPay:

```text
IPN:    https://<ref>.supabase.co/functions/v1/vnpay-ipn
Return: https://<ref>.supabase.co/functions/v1/vnpay-return
```

Edge Functions có thể dùng IP egress động. Nếu VNPay merchant yêu cầu allowlist IP tĩnh, đặt phần gọi query/refund trên backend/proxy có IP tĩnh được duyệt trước khi nghiệm thu production. Chỉ nhập một chuỗi IP vào secret không làm IP egress trở thành tĩnh.

## 7. Đối soát định kỳ

Sau khi deploy function:

1. Bật pg_cron, pg_net và Vault trong Dashboard theo khả năng của dự án.
2. Tạo Vault secret `mathlingo_project_url` bằng URL Supabase; tạo `mathlingo_job_key` bằng **cùng giá trị** `COMMERCE_JOB_KEY`.
3. Chạy thủ công `supabase/operations/schedule_reconciliation.sql`. Script tạo/cập nhật job mỗi 5 phút; không nằm trong migrations bắt buộc.
4. Theo dõi Cron run details, Edge logs và response HTTP. HTTP được pg_net nhận không đồng nghĩa xử lý giao dịch đã thành công.

Job xử lý tối đa 20 đơn/lượt, 4 yêu cầu đồng thời; query bị giới hạn một lần/đơn/phút. Job đối soát đơn gần đây và refund chưa rõ, đánh dấu đơn quá hạn, cập nhật quyền hết hạn/kỳ sắp bắt đầu, tạo thông báo sắp hết hạn, dọn token và cache AI cũ. Quyền Plus vẫn kiểm tra ngày hết hạn khi gọi RPC dù job chưa chạy.

Nếu Cron không khả dụng, scheduler backend của bạn có thể POST vào `commerce-reconcile` với header `x-job-key`. Không gọi endpoint này từ app và không công khai job key.

## 8. Mở bán và kiểm thử giao dịch

Trong admin, đặt giá nháp tháng/năm và bật mở bán. Giá 0 không thể publish. Giá đã có đơn chỉ ngừng bán; tạo phiên bản giá mới để thay số tiền/kỳ. Đơn giữ snapshot cũ.

Đơn VNPay mới nằm ở `learning_orders`, payment đã xác minh nằm ở `learning_payments`. Quyền đang có được giữ qua backfill từ `subscriptions`. Không tự coi các dòng `paid` trong bảng cũ là giao dịch VNPay mới đã xác minh hoặc cấp thêm kỳ Plus. Admin xem lịch sử cũ tại chi tiết gia đình, trường `legacy_commerce`, để hỗ trợ tra cứu.

Kiểm thử sandbox ít nhất:

1. Phụ huynh xác minh email → PIN → tạo bé → học Basic.
2. Chọn gói → xác nhận giá toàn kỳ/không tự gia hạn → VNPay → quay lại kiểm tra → một payment/một kỳ Plus.
3. IPN gửi lặp 5 lần không tăng thời hạn lặp; sai chữ ký/số tiền không cấp quyền.
4. Đóng app/mất mạng sau trả tiền: mở lịch sử và đối soát, không trả lần hai để khôi phục quyền.
5. Mua nối kỳ, Plus hết hạn có 3 bé, chọn một bé Basic và gia hạn lại; dữ liệu cả ba giữ nguyên.
6. Admin hoàn toàn phần có lý do; thành công mới thu hồi kỳ tương ứng. Timeout/chữ ký sai giữ `unknown`, giữ quyền cho đến khi có xác nhận. Đối soát có thể khôi phục trạng thái refund khi VNPay trả loại `02` và thành công.
7. Refund bị provider từ chối rõ ràng có trạng thái `failed`; sau khi kiểm tra nguyên nhân có thể tạo yêu cầu mới. `processing`/`unknown` không được gửi hoàn tiền lần nữa. Không sửa thành `succeeded` bằng client hoặc chỉ dựa vào lời người dùng.
8. Phụ huynh gửi yêu cầu hỗ trợ gắn đơn; admin tra gia đình/đơn, phản hồi, phụ huynh nhận thông báo.

Không triển khai tự gia hạn/hủy gia hạn vì đây là mua một kỳ VNPay. Chuyển sang merchant production bằng bộ secrets/URLs đồng bộ sau khi VNPay xác nhận sandbox; thực hiện một giao dịch nhỏ và đối chiếu cổng merchant trước mở bán.

## 9. CMS, học tập, AI và offline

CMS: admin/moderator tạo chủ đề → tạo/sửa nháp → chọn dạng câu hỏi và dùng JSON mẫu cho payload/gợi ý → xem trước → kiểm tra/xuất bản. Server xác nhận options/đáp án, số lượng, giờ/phút bước 5, kích thước lưới, đáp số tự luận. Mỗi lần publish tạo question IDs mới; attempts cũ vẫn trỏ câu hỏi cũ. Ẩn bài ngăn bắt đầu/học tiếp bài đó.

Tự luận yêu cầu cách giải tối thiểu 5 ký tự và đáp số khớp trường đáp số đã biên tập. Đây là kiểm tra đáp số có cấu trúc, **chưa chấm chất lượng lập luận tự do bằng AI**. Năm đề seed cũ có đáp số được khai báo rõ; đề hai tuổi nhập `40;10` theo hướng dẫn. Không lấy một kết quả trung gian làm đáp án.

Học: bắt đầu/tiếp tục phiên từ server; đáp án gửi giá trị và question ID, không gửi boolean đúng/số XP. Làm lại bài giữ best accuracy, không thưởng lần hai. Sai bài học mất tim, luyện 5 câu đúng hồi đầy tim, đấu trường thưởng từ câu trả lời và tối đa 5 thử thách hoàn thành/ngày. Mỗi nhóm cùng lớp tối đa 30, mã tuần ISO year/week tính tại server. Trang bị lại đồ sở hữu miễn phí.

Thời gian tính từ heartbeat foreground khoảng 20 giây, chặn ở hạn theo ngày Việt Nam. Khoảng mất liên lạc trên 45 giây không được coi là thời lượng hoạt động đã xác nhận; vì vậy báo cáo không bao gồm đầy đủ thời gian đọc ngoại tuyến. Nhắc nghỉ sau 10 phút trong màn học.

Offline: cache có namespace tài khoản/bé, tối đa 15 phút và bị chặn bởi ngày hết Plus/thời gian học còn lại. Cho xem bài đang mở, giữ tự luận/trạng thái và **một đáp án đang chờ**; cần máy chủ chấm trước khi sang câu tiếp theo/nhận thưởng. Reconnect phát lại với cùng request ID; câu đã đổi hoặc mất quyền bị từ chối và tải lại. Đăng xuất xóa cache của tài khoản. Đây là cơ chế khôi phục gián đoạn; chưa phải bộ học Plus tải xuống hoàn toàn. Đồng hồ/cache thiết bị không được dùng để cấp quyền hoặc thưởng ở server.

AI: deploy và đặt secrets trước; trong admin cấu hình quota Basic/Plus rồi bật. Mỗi OCR hoặc lần tạo gợi ý tính một lượt theo gia đình/ngày, có chống lặp/rate limit. Ảnh JPEG/PNG dưới 3 MB; OCR → sửa đề → gợi ý. Không lưu ảnh trong Storage, response phục vụ retry giữ tối đa khoảng 2 ngày và dọn bằng job. Ảnh/đề vẫn được gửi tới provider; rà chính sách dữ liệu provider trước sử dụng thật. Không quảng bá AI không giới hạn hoặc coi gợi ý là lời giải được kiểm chứng.

## 10. Cấu hình app và build

Sao chép `config/app.example.json` thành `config/app.json`, điền URL và public anon/publishable key của **đúng môi trường đã chạy migrations**. File local được Git bỏ qua. Workspace hiện có cấu hình local lấy từ public config cũ; kiểm tra lại nếu chuyển staging/production.

```powershell
flutter run --dart-define-from-file=config/app.json
./scripts/build-android.ps1 -Mode debug
```

APK debug: `build/app/outputs/flutter-apk/app-debug.apk`. Bản debug dùng khóa debug để kiểm thử. Build không truyền config vẫn biên dịch được để CI kiểm tra, nhưng không đăng nhập được.

Release: tự tạo/giữ upload keystore ở vị trí an toàn, sao chép `android/key.properties.example` thành `android/key.properties`, điền thông tin của khóa. Không commit keystore/password. Gradle không dùng khóa debug cho release và sẽ chặn build release khi thiếu key.

```powershell
./scripts/build-android.ps1 -Mode release
# Nếu cần AAB sau khi cấu hình key:
flutter build appbundle --release --no-pub --dart-define-from-file=config/app.json
```

Chưa có keystore thật nên chưa tạo APK/AAB release có chữ ký production. iOS cần signing/bundle identifier/Associated setup trên máy macOS; kiểm thử ảnh camera/thư viện và link Auth thật. VNPay ngoài ứng dụng đang phục vụ kênh đã chọn; đánh giá yêu cầu thanh toán nội dung số của store trước khi gửi duyệt store.

## 11. Nghiệm thu và vận hành

Workflow `.github/workflows/verify.yml` chạy analyze, Flutter tests, Node handler tests và build debug, không truy cập Cloud. SQL staging và merchant/AI/device tests là bước triển khai riêng.

Trước mở bán: regression SQL đạt, Auth email/deep link đạt, cả bốn role đúng quyền, sandbox đạt, lịch Cron hoạt động, nội dung được duyệt, kiểm tra điện thoại màn nhỏ/chữ lớn/dark mode và mạng chập chờn. Không dùng kết quả Node mock làm bằng chứng thanh toán thật hoặc RLS đã đạt.

Theo dõi đơn pending/expired đã trừ tiền, refund unknown, lỗi Edge, thời gian cấp Plus, số support đang chờ và Cron thất bại. Không ghi PIN/ảnh/thẻ/secret vào log. Mỗi yêu cầu tài chính chưa rõ phải đối chiếu provider trước khi sửa dữ liệu hoặc gửi lại.

Rollback: tạm ngừng mở bán bằng unpublish giá; giữ IPN/query để tiếp nhận giao dịch đã phát sinh. Không xóa orders/payments/periods hoặc chạy lại seed để khôi phục. Khôi phục database từ backup cần phối hợp đối soát các giao dịch xảy ra sau snapshot. App cũ không tương thích quyền mới; ưu tiên sửa tiến về phía trước sau khi thử staging.

Tài liệu đối chiếu: [VNPay query/refund](https://sandbox.vnpayment.vn/apis/docs/truy-van-hoan-tien/querydr%26refund.html), [Supabase scheduling](https://supabase.com/docs/guides/functions/schedule-functions), [Gemini image input](https://ai.google.dev/gemini-api/docs/image-understanding), [Gemini structured output](https://ai.google.dev/gemini-api/docs/structured-output).
