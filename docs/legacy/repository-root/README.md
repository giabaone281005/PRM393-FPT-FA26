# MathLingo — Flutter + Supabase

Ứng dụng học toán lớp 1–5 với tài khoản phụ huynh, hồ sơ bé, lộ trình tương tác, luyện tập hồi tim, đấu trường, tủ đồ và bán gói học theo gia đình qua VNPay.

Đọc [hướng dẫn triển khai](DEPLOYMENT_GUIDE.md), [kế hoạch theo role](ROLE_COMMERCE_DEVELOPMENT_PLAN.md) và [đối chiếu triển khai](ROLE_COMMERCE_IMPLEMENTATION_STATUS.md).

## Trạng thái hoàn thiện — 18/10/2026

Các luồng cốt lõi đã có mã tích hợp Supabase và đã được kiểm thử như bên dưới. Dự án đang ở giai đoạn QA/tích hợp, **chưa nghiệm thu phát hành production**. “Đã có mã”, “đã deploy” và “đã chạy với nhà cung cấp thật” là các mức hoàn thành khác nhau.

Sau khi đồng bộ `main`, codebase còn có thêm giao diện ví/trial, lựa chọn MoMo/VNPay/QR và cổng thanh toán demo từ các commit của nhóm. Các luồng bổ sung này chưa được nghiệm thu với provider thật; kết quả demo không phải bằng chứng đã thu tiền. Dependencies nhận giọng nói và QR đã được khôi phục để mã hiện có biên dịch đầy đủ.

| Phân hệ | Đã hoàn thành trong codebase | Bằng chứng và giới hạn |
|---|---|---|
| Tài khoản | Đăng nhập/đăng xuất, đăng ký, xác minh email, khôi phục mật khẩu và session Supabase | Đăng nhập thật bằng các tài khoản QA đạt; chưa nghiệm thu gửi email SMTP và deep link trên thiết bị |
| Gia đình và quyền | Hồ sơ bé, chọn bé, giới hạn số bé theo gói, PIN phụ huynh trên server, quyền admin/moderator và RLS | SQL/HTTP kiểm tra cách ly gia đình, PIN gắn với phiên đăng nhập và giới hạn vai trò đạt |
| Giáo trình và bản đồ | Tải lộ trình từ RPC, tiến độ theo ID bài; sửa lỗi ẩn/đánh dấu nhầm các bài có cùng số hiển thị | Cloud có 155 bài/1.505 câu hỏi ở lần kiểm kê; đây là nội dung seed cần tiếp tục biên tập |
| Học tập và phần thưởng | Server chấm đáp án, lưu attempts/phiên dở, tiến độ, tim, XP/sao; retry không thưởng lặp | Regression SQL về đáp án, độ chính xác, thưởng và hồi tim đạt |
| Thống kê và streak | Tài khoản đăng nhập đọc số lượt đúng/sai và streak từ server, đếm chính xác vượt giới hạn dòng API | Không dùng số đếm local để thay thế kết quả server khi truy vấn lỗi |
| Thời gian và dashboard phụ huynh | Ghi heartbeat theo vòng đời/route, xếp hàng bản ghi pause; tải báo cáo khi mở/quay lại và mỗi 30 giây; hiển thị thời lượng phiên đã xác nhận, lần đồng bộ và trạng thái cũ | Phiên QA online ghi thêm **122 giây**, khớp session và usage. Chưa nghiệm thu đủ hai thiết bị, qua nửa đêm và đóng tiến trình bất ngờ |
| Ôn câu sai | Lịch sử từ attempts server, lưu trạng thái đã ôn/ẩn theo bé trên Cloud; sai lại thì mở lại | Migration mới đã áp dụng; SQL và HTTP QA đạt. Đánh dấu ôn không sửa điểm/thưởng; không nhập điểm local cũ thành kết quả đã xác minh |
| Luyện tập, đấu trường, tủ đồ | Luyện 5 câu hồi tim, đấu trường nhóm tối đa 30, sở hữu/mua/trang bị vật phẩm qua server | Có kiểm thử quyền, hồi tim và chống thưởng/mua lặp; chưa kiểm thử tải đồng thời lớn |
| Admin, CMS và hỗ trợ | Quản lý nội dung nháp/xem trước/xuất bản, giá phiên bản, đơn, cấp bù gói, roles/audit, hỗ trợ và thông báo | Kiểm thử quyền admin/moderator đạt; moderator không có quyền tài chính hoặc cấp role |
| VNPay | Luồng order/checkout/IPN/query, lịch sử, hoàn tiền và đối soát; kiểm tra chữ ký và cập nhật quyền qua server | Đã deploy backend, SQL/Node và kiểm tra từ chối truy cập đạt; **chưa thực hiện thanh toán/hoàn tiền merchant thật** |
| AI | Chọn/chụp ảnh, OCR → sửa đề → gợi ý, repository, quota và kiểm tra output; giao diện đọc trạng thái bật/tắt thật | Đã deploy `ai-tutor`; **AI vẫn tắt**, provider chưa sẵn sàng (HTTP 503), chưa nghiệm thu OCR/gợi ý thật |
| Cache và phục hồi | Cache phiên có giới hạn và outbox đáp án để khôi phục gián đoạn mạng ngắn | Kết quả/thưởng cần server xác nhận; chưa có tải trọn gói Plus để học offline hoàn toàn |

### Dữ liệu và triển khai đã xác nhận

- Các luồng học của tài khoản đăng nhập dùng dữ liệu/kết quả Supabase; không có cơ sở để tuyên bố mọi dữ liệu toàn dự án đều đã được nghiệm thu. Cấu hình giao diện, cache cục bộ và bài luyện sinh từ thuật toán có vai trò riêng; nội dung seed không đồng nghĩa với nội dung đã biên tập.
- Migration `20261024000000_cloud_wrong_answer_reviews.sql` đã áp dụng và đối chiếu version với Cloud. Các đối tượng từ migrations 18–23 hiện diện nhưng lịch sử cũ vẫn cần đối chiếu đầy đủ; không đánh dấu tất cả đã áp dụng chỉ dựa trên tên bảng.
- Đã deploy `ai-tutor` **ACTIVE v1**, `vnpay-refund` **ACTIVE v1**, `commerce-reconcile` **ACTIVE v2**. Đối soát đã sửa lỗi thiếu khóa gây 500: thiếu/sai khóa nay trả 401 trước khi truy cập database/provider.
- AI giữ tắt; chưa bật lịch đối soát tự động, chưa gửi ảnh/đề tới Gemini và chưa thực hiện giao dịch/hoàn tiền trong đợt triển khai. Deploy thành công không thay thế nghiệm thu provider.
- Giữ dữ liệu học và commerce legacy; không reset hoặc xóa dữ liệu người dùng trong đợt sửa/triển khai này.

### Kết quả kiểm thử đã thực hiện

| Kiểm tra | Kết quả gần nhất |
|---|---|
| Flutter analyze | Đạt, không có lỗi/cảnh báo |
| Toàn bộ Flutter tests | **212 đạt** |
| Node backend tests | **22 đạt**, có regression thiếu/empty job key |
| Kiểm tra cấu trúc SQL | **25 file đạt**; không thay thế chạy SQL runtime |
| SQL trên Cloud | Commerce, role/learning, session time, content/payment, legacy compatibility và wrong-answer review đạt; fixture rollback |
| HTTP QA và kiểm soát truy cập | Auth/role/report/history đạt; chặn truy cập chéo gia đình; refund từ chối phụ huynh 403 và đối soát từ chối khóa sai 401 |
| Android debug | Build, cài và khởi động trên Pixel 9 emulator đạt |
| Android release | Đã thử build, bị chặn do thiếu cấu hình ký `android/key.properties` |

Các con số trên là kết quả đã chạy, không phải cam kết rằng mọi kịch bản sản phẩm đã đạt. Xem [kiểm thử chi tiết](VALIDATION.md), [audit và bằng chứng triển khai](supabase/AUDIT_20261018.md), [kế hoạch hoàn thiện còn lại](IMPLEMENTATION_COMPLETION_PLAN.md).

### Phần còn lại trước phát hành

- Nghiệm thu merchant VNPay (thanh toán/pending/callback/refund/đối soát), cấu hình khóa job và lịch tự động sau khi được duyệt; cấu hình/kiểm thử Gemini trước khi bật AI.
- Kiểm thử đăng ký/xác minh/khôi phục qua email thật và deep link; hoàn thiện cấu hình ký release, nghiệm thu iOS nếu phát hành trên nền tảng này.
- Đối chiếu đầy đủ migration history/định nghĩa Cloud và chạy migration trên môi trường sạch/staging; lần thử chạy lại migration ôn câu sai còn lỗi requestState, chưa xác minh được idempotency DDL. Idempotency RPC đã kiểm thử đạt.
- Kiểm thử thời gian qua nửa đêm, nhiều thiết bị và đóng app bất ngờ. Báo cáo hiện ghép nhiều request, chưa có snapshot nguyên tử theo thời điểm server và chưa bổ sung đủ ngày trống của biểu đồ 7 ngày.
- Biên tập 50 nhóm câu hỏi seed lặp, rà đáp án/độ phù hợp lớp và hai tập số bài lớp 5; không xóa liên kết tiến độ cũ.
- Chốt phạm vi MoMo/trial và cơ chế xác minh sở hữu ví. Có mã/schema liên quan không đồng nghĩa với luồng Flutter hoặc nghiệp vụ đã nghiệm thu.

## Chạy ứng dụng

Flutter 3.47.4/Dart 3.13.3 đã được dùng để kiểm thử. Sao chép `config/app.example.json` thành `config/app.json`, điền Supabase URL và public key; không đưa service key vào Flutter.

```powershell
flutter pub get
flutter run --dart-define-from-file=config/app.json
```

`config/app.json` không nằm trong Git. Sau khi clone/pull, từng thành viên cần điền URL và public key thật của cùng dự án; sao chép file mẫu nhưng giữ `YOUR_...` chưa đủ để kết nối. Không đưa service/secret key vào ứng dụng.

Nếu chạy bằng nút Run của IDE, cấu hình thêm đối số `--dart-define-from-file=config/app.json`, hoặc dùng lệnh trên trong thư mục dự án. Chỉ tạo file JSON rồi chạy `flutter run` sẽ không truyền cấu hình vào ứng dụng. Sau khi đổi cấu hình, dừng ứng dụng và chạy lại bằng lệnh đầy đủ.

## Kiểm tra mã

```powershell
flutter analyze --no-pub
flutter test --no-pub
node --test test_backend/*.test.mjs
node scripts/check-sql.mjs
```

Node 24 chạy các handler TypeScript trong môi trường giả lập Deno/fetch. Kiểm thử đó không thay thế nghiệm thu Edge Functions và provider thật. Các lệnh trên chỉ chạy kiểm tra local; không tự áp migration hoặc chạy SQL trên Cloud. Các bộ regression SQL trong `supabase/tests/` cần kết nối QA/staging có quyền phù hợp, dùng transaction và ROLLBACK fixture.

## Những luồng chính

- Phụ huynh: Auth thật/PIN server, quản lý bé, báo cáo, giới hạn học, gói và lịch sử đơn, thông báo và hỗ trợ.
- Học sinh: server chấm đáp án/ghi tiến độ và thưởng, tiếp tục bài dở, luyện 5 câu hồi tim, đấu trường nhóm 30, sở hữu/trang bị đồ.
- Admin: catalog/giá phiên bản, đơn/đối soát/refund, hỗ trợ gia đình, phân trang, cấp bù, roles/audit và cấu hình AI.
- Moderator: CMS nháp/xem trước/xuất bản; không được vận hành tài chính hoặc role.
- AI: chọn/chụp ảnh → OCR → sửa đề → gợi ý; backend giữ secret và quota. Mặc định tắt cho đến khi cấu hình/kiểm thử.
- Cache/outbox giúp khôi phục mất mạng ngắn; kết quả và phần thưởng vẫn cần xác nhận server.

## Database và phát hành

Kiểm tra Cloud ngày 18/10/2026 xác nhận các đối tượng từ migrations `20261018 → 20261023` đã hiện diện, nhưng lịch sử migration chưa đầy đủ. Phải đối chiếu định nghĩa trước khi sửa lịch sử hoặc triển khai tiếp; không chạy lại nguyên các migration cũ, seed hoặc reset Cloud. Xem [audit tích hợp và kết quả kiểm thử](supabase/AUDIT_20261018.md).

Commerce mới dùng `learning_orders`/`learning_payments` để tương thích với hai bảng `orders`/`payments` legacy đã có trên Cloud. Khi copy SQL từ bản trước, cần lấy lại nội dung migrations mới nhất.

`scripts/build-android.ps1` hỗ trợ debug/release. Release yêu cầu upload keystore riêng qua `android/key.properties`; không dùng khóa debug. Giá gói và quota AI được quản lý trên server. Không coi dữ liệu seed, trial hoặc chức năng demo là bằng chứng đã thanh toán thật hay đã sẵn sàng mở bán.
