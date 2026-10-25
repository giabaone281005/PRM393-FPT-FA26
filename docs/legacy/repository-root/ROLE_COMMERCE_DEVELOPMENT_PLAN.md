# MathLingo — Kế hoạch hoàn thiện theo vai trò và bán gói học tập

Ngày: 16/10/2026. Kế hoạch gốc và đối chiếu triển khai.

## Trạng thái triển khai hiện tại

Đã triển khai mã cho luồng phụ huynh/học sinh/admin/moderator, thương mại VNPay, phiên học được chấm server, tủ đồ, đấu trường, CMS, hỗ trợ, thông báo, OCR/gợi ý AI có quota và khôi phục gián đoạn mạng. Xem [hướng dẫn triển khai đầy đủ](DEPLOYMENT_GUIDE.md) và [bảng đối chiếu](ROLE_COMMERCE_IMPLEMENTATION_STATUS.md).

Schema Cloud được người dùng cung cấp sau đó có thêm `orders`, `payments` và `subscription_plans` cũ ngoài giả định ban đầu. Tên bảng thương mại mới đã đổi thành `learning_orders`/`learning_payments` để giữ nguyên hệ thống cũ; dùng các file migrations mới nhất trong repository.

Có **bốn migrations mới 20261018 → 20261021, chưa chạy**. Bốn migrations cũ giữ nguyên. Theo yêu cầu người dùng, chỉ tạo script kiểm thử SQL, không tải PostgreSQL và không thay đổi Supabase Cloud trong phiên này. Kiểm thử database/staging, merchant VNPay, dịch vụ AI, thiết bị và ký production vẫn cần thực hiện theo hướng dẫn trước phát hành.

Phần bên dưới là kế hoạch gốc; các nhận định “chưa có/chưa triển khai” mô tả thời điểm khảo sát. Kênh đã chốt sau khảo sát: **VNPay qua backend, mua từng kỳ không tự gia hạn**. MoMo/IAP, offline Plus hoàn toàn, coupon/referral và luyện tập thích ứng vẫn là các hướng mở rộng sau MVP, không phải tính năng được bán trong bản này.

## 1. Phạm vi và hiện trạng đã xác nhận

Người dùng xác nhận tất cả migrations đã chạy trên Supabase. Kế hoạch lấy trạng thái cuối của 4 migration trong repository làm cơ sở: 19 bảng public và view v_leaderboard; auth.users do Supabase quản lý riêng. Chưa truy vấn Cloud độc lập để phát hiện thay đổi thủ công ngoài các migration.

Hiện có Basic/Plus, subscriptions, subscription_logs và RPC admin_upgrade_subscription. Đây mới là quản lý cấp quyền; chưa có cửa hàng gói, đơn hàng, thanh toán hoặc lịch sử giao dịch. Nút dùng thử Plus hiện chỉ thay đổi state trong app.

Mục tiêu MVP: phụ huynh mua được gói; quyền học có hiệu lực đúng; học sinh học liền mạch; admin vận hành được nội dung, giao dịch và hỗ trợ. Giữ Flutter + Provider + Supabase, cải tiến dần kiến trúc hiện tại.

Các lựa chọn sản phẩm dưới đây là đề xuất để triển khai, không phải thông số đã được người dùng chốt: gói theo gia đình, Basic miễn phí/Plus trả phí, chu kỳ tháng/năm, tối đa 3 bé. Chưa đặt giá bán, số ngày trial hoặc quota AI khi chưa có quyết định kinh doanh và dữ liệu chi phí.

## 2. Vai trò và trải nghiệm mục tiêu

### 2.1. Phụ huynh — người mua và quản lý gia đình

Luồng lần đầu: Đăng ký → xác minh email → tạo bé đầu tiên → đặt PIN → xem tổng quan → cho bé bắt đầu học. Có thể học bằng Basic trước, không bắt mua ngay khi tạo tài khoản.

Luồng mua: Cổng phụ huynh → Gói học tập → so sánh quyền lợi → chọn tháng/năm → xác nhận giá và điều kiện → thanh toán → xác minh → quyền học được cập nhật → tiếp tục bài học/chọn bé.

Điều hướng đề xuất trong chế độ phụ huynh: Tổng quan / Các bé / Gói học tập / Tài khoản. Lịch sử mua nằm trong Gói học tập; thông báo nằm ở đầu trang. Đăng nhập lại mở đúng chế độ trước đó; trở lại chế độ phụ huynh từ màn hình của bé phải qua cổng bảo vệ.

| Nhóm | Đã có | Cần sửa | Cần hoàn thiện/bổ sung |
|---|---|---|---|
| Tài khoản | Đăng ký, đăng nhập, UI OTP | Bỏ success giả, OTP local và nhận diện admin theo email | Email verification thật, quên/đổi mật khẩu, session restore, đăng xuất sạch state |
| Hồ sơ bé | Danh sách, thêm, sửa, xóa, chuyển bé | Sửa tên/lớp phải lưu thật; tạo/xóa thất bại không báo thành công; lọc theo gia đình | Trạng thái 0 bé, lưu bé được chọn; giải thích giới hạn theo gói |
| Theo dõi học tập | Thanh kỹ năng và số thời gian | Thay số mẫu bằng sessions/attempts thật | Tổng quan hôm nay/7 ngày; kỹ năng mạnh/yếu, bài gần nhất, gợi ý ôn |
| Giới hạn học | Slider và Parent Gate | PIN mặc định/plaintext; giới hạn chưa được thi hành | Đếm thời gian học foreground; chặn đúng hạn, nghỉ giải lao, đổi hạn có xác thực |
| Mua gói | Popup giới thiệu Plus | Bỏ kích hoạt trial chỉ trong RAM; không hứa AI chưa hoạt động | Danh mục, so sánh, checkout, trạng thái thanh toán, lịch sử, khôi phục mua |
| Quản lý gói | Hiển thị tier/ngày hết hạn | Quyền lợi UI/backend đang không thống nhất | Ngày gia hạn, hủy gia hạn, hết hạn, grace period theo nhà cung cấp, hỗ trợ giao dịch |

Trải nghiệm mua phải có đủ trạng thái: đang tải sản phẩm, không có gói khả dụng, chưa mua, đang xử lý, hủy, lỗi, đã thanh toán chờ xác minh và đã kích hoạt. Không hiển thị “thất bại, mua lại” khi nhà cung cấp đã thu tiền nhưng backend chưa nhận thông báo.

Trước khi mua hiển thị số bé, nội dung được học, thời hạn, giá toàn kỳ, có/không tự gia hạn và quyền lợi đang thực sự khả dụng. Không dùng giá tháng quy đổi làm giá thanh toán chính của gói năm. Lịch sử giao dịch có mã đơn và nút kiểm tra trạng thái/hỗ trợ.

### 2.2. Học sinh — học, luyện tập và nhận phản hồi

Học sinh hiện là kid_profiles dưới tài khoản phụ huynh, không có email/mật khẩu riêng. Giữ mô hình này cho MVP. Chế độ học sinh là chế độ sử dụng, không tự động trở thành một role Supabase độc lập; Parent Gate ở UI không thay thế kiểm soát thao tác nhạy cảm ở server.

Luồng chính: Chọn bé → Học tiếp → lý thuyết ngắn → bài tương tác → phản hồi/gợi ý → hoàn thành → nhận thưởng → bài tiếp theo. Mini game khuyến nghị là hoạt động thưởng tùy chọn sau mục tiêu học, không bắt trẻ thắng trò chơi mới ghi nhận kiến thức đã đạt.

Điều hướng: Trang chủ / Bản đồ / Luyện tập / Hồ sơ. Đấu trường truy cập từ Trang chủ hoặc Luyện tập; tủ đồ trong Hồ sơ. Một nút “Học tiếp” nổi bật hơn các hoạt động phụ. AI chỉ xuất hiện khi chức năng thật đã sẵn sàng.

| Nhóm | Đã có | Cần sửa | Cần hoàn thiện/bổ sung |
|---|---|---|---|
| Lộ trình | Bản đồ lớp 1–5 | Bỏ 13 bài hoàn thành sẵn; lấy progress của bé; tránh async ghi đè khi đổi bé | Phân biệt khóa do lộ trình và khóa do quyền gói; CTA phù hợp |
| Bài học | Theory/quiz/essay/game, 5 widget | Không hoàn tất khi chưa đủ mục tiêu; accuracy thật; chống trả lời/thưởng lặp | Lưu phiên dở, phản hồi theo lỗi, lời giải từng bước, kiểm tra tự luận có cấu trúc |
| Tim | Trừ/hồi tim, vườn | Thống nhất quy tắc hồi tim và log; không nhân đôi khi retry | Từ hết tim đi luyện tập rồi quay về phiên học đang dở |
| Streak/XP | Có state và ghi Cloud | Streak theo ngày server; XP/sao do server chốt | Mục tiêu hằng ngày, giải thích thưởng; học lại có giới hạn thưởng rõ ràng |
| Đấu trường | BXH, trò chơi | Nhóm 30 thật; đúng ISO week-year; chống gửi XP tùy ý | Vị trí của bé ngoài top, kết quả tuần, nhóm cùng lớp |
| Tủ đồ | Mua/trang bị | Nối inventory/equipment/purchase_item; sở hữu và trang bị là hai trạng thái riêng | Xem đồ đã sở hữu, preview; trang bị lại miễn phí |
| AI | Màn hình mô phỏng | Ghi rõ demo hoặc ẩn nút trong bản dùng thật | Ảnh thật, OCR, cho sửa đề, gợi mở có kiểm chứng, lỗi/quota rõ ràng |
| Trải nghiệm | Hoạt ảnh và theme | Kiểm thử màn nhỏ/font lớn/dark mode; tránh tải lại mất bài | Âm thanh tùy chọn, nghỉ giải lao, thông báo offline và tiến độ chờ sync |

Khi gặp bài ngoài gói: trẻ thấy “Nhờ phụ huynh mở bài học” và nút qua Parent Gate; không thấy giá, checkout hoặc thúc ép mua. Không bán tim, không khóa đường hồi tim miễn phí. Khi gói hết hạn vẫn giữ thành tích, lịch sử và trang phục đã mua bằng sao.

### 2.3. Admin — vận hành sản phẩm

Hiện dashboard chủ yếu tìm phụ huynh và đổi Basic/Plus. Cần điều hướng riêng: Tổng quan / Tài khoản / Gói học tập / Đơn hàng / Nội dung / Nhật ký. Dashboard desktop/tablet ưu tiên bảng có phân trang và lọc phía server, mobile vẫn thao tác được.

| Nhóm | Đã có | Cần sửa | Cần hoàn thiện/bổ sung |
|---|---|---|---|
| Phân quyền | admins, user_roles, is_admin | Thống nhất user_roles; bỏ email hardcode; khóa API chứ không chỉ ẩn UI | Quyền theo thao tác, log khi cấp/hạ quyền; tài khoản admin bootstrap có kiểm soát |
| Phụ huynh | Danh sách và bộ lọc | Không tải toàn bộ parents/subscriptions/kids để join trong app; search debounce | Chi tiết gia đình, gói hiệu lực, lịch sử cấp quyền và giao dịch |
| Danh mục gói | Chưa có | Giá/quyền lợi không hardcode trong popup | Tạo nháp, publish/unpublish, phiên bản giá/quyền lợi, mapping sản phẩm store |
| Đơn/thanh toán | Chưa có | Không coi admin bấm đổi gói là một thanh toán | Theo dõi đơn, đối soát, tra mã giao dịch, kiểm tra lại/khôi phục quyền |
| Hỗ trợ | RPC đổi gói có log | Giới hạn cấp quyền, nhập lý do bắt buộc | Cấp bù thời gian/cancel theo chính sách, audit trước/sau; hoàn tiền qua nhà cung cấp |
| Nội dung | Có seed | Loại lặp, rà đáp án, đủ payload 5 dạng | Chủ đề/kỹ năng, editor, preview, validation, nháp/xuất bản và version |
| Vận hành | Chỉ số phụ huynh/Plus/bé | Tách tổng số khỏi bộ lọc, tính chỉ số từ server | Lỗi thanh toán, doanh thu đã đối soát, tỷ lệ kích hoạt, phiên học và thông báo lỗi |

Moderator đã có trong enum nhưng chưa có sản phẩm tương ứng: giai đoạn sau cho biên tập/xuất bản nội dung theo quyền, không xem thanh toán, đổi role hoặc cấp gói. Không xây thêm dashboard moderator riêng trong MVP; dùng màn nội dung với quyền giới hạn.

## 3. Mô hình gói và quy tắc kinh doanh đề xuất

| Quyền lợi | Basic | Plus tháng/năm |
|---|---|---|
| Hồ sơ bé hoạt động | 1 | Tối đa 3 |
| Nội dung | Bài miễn phí đã chọn theo lớp | Nội dung Plus đã xuất bản, dùng cho các bé trong gia đình |
| Luyện tập hồi tim | Miễn phí | Miễn phí |
| Báo cáo | Tiến độ và thời lượng cơ bản | Phân tích kỹ năng và đề xuất ôn khi có đủ dữ liệu |
| AI | Chưa bán khi chưa triển khai | Chỉ đưa vào quyền lợi sau nghiệm thu; quota cấu hình theo chi phí |
| Trang phục | Đổi bằng sao và sở hữu lâu dài | Ưu đãi tùy chọn sau MVP; không tự hứa “trọn bộ miễn phí” |

Tháng/năm là hai lựa chọn thanh toán cùng một tập quyền lợi, chưa cần tạo hai hệ gói khác nhau. Nếu sau này bán khóa theo từng lớp/chủ đề hoặc gán một gói cho một bé, bổ sung quyền truy cập có phạm vi; không nhét logic này vào tier basic/plus hiện tại.

Quy tắc phải có trước khi code checkout:

1. Mỗi gia đình có một gói hiệu lực tại một thời điểm trong MVP; giữ đầy đủ các kỳ mua và lịch sử ở bảng riêng.
2. Tiền chỉ đi qua checkout đã chọn; sao trong app không đổi sang tiền và không dùng mua gói học.
3. Với gói tự gia hạn, hủy gia hạn vẫn được dùng đến hết kỳ đã trả; refund/revoke xử lý theo trạng thái xác minh của nhà cung cấp.
4. Với mua một kỳ không tự gia hạn trên kênh phù hợp, mua nối cùng gói bắt đầu từ max(thời điểm hiện tại, thời điểm hết quyền hiện tại). Không áp dụng phép cộng kỳ này máy móc cho subscription từ store; dùng kỳ store xác nhận.
5. Chuyển tháng/năm áp dụng theo khả năng và quy tắc nhà cung cấp; MVP không tự tính hoàn tiền bù trừ. Màn hình phải thể hiện ngày đổi có hiệu lực.
6. Trial nếu có phải do server/store ghi nhận, chỉ đủ điều kiện một lần theo chính sách; không reset khi cài lại app.
7. Hết Plus khi có 3 bé: không xóa bé. Phụ huynh chọn 1 bé hoạt động Basic; hồ sơ còn lại được giữ, có thể xem lịch sử và mở lại khi gia hạn. Danh sách bé đang có và slot hoạt động là hai khái niệm khác nhau.
8. Khi offline, dùng quyền đã xác minh được cache đến thời hạn hợp lệ; không mở Plus vô thời hạn bằng đồng hồ thiết bị. MVP có thể yêu cầu mạng khi bắt đầu bài Plus và khi mua/đổi quyền; offline Plus đầy đủ là giai đoạn sau.
9. Không nhận thanh toán cho quyền lợi AI hoặc nội dung chưa có. Mọi thay đổi giá/quyền lợi có phiên bản; giao dịch cũ giữ snapshot để tra cứu.

Kênh thanh toán là quyết định cần chốt trước tích hợp. Nếu phát hành trên Google Play/App Store, mặc định thiết kế cho Google Play Billing/Apple In-App Purchase đối với nội dung số, rồi kiểm tra ngoại lệ theo thị trường/kênh phân phối thực tế. Nếu là APK nội bộ/bản demo, dùng sandbox trước; thanh toán web/cổng ngoài là hướng riêng theo kênh đã chọn. Chưa tự chọn MoMo/VNPay hoặc coi QR trong app là phương án chung cho mọi nền tảng.

Nguồn chính sách: [Google Play Payments](https://support.google.com/googleplay/android-developer/answer/9858738), [Apple In-App Purchase guidelines](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase). Điều kiện và ngoại lệ phải kiểm tra lại khi phát hành.

## 4. Luồng mua và kiến trúc xử lý

1. App tải catalog đã xuất bản và sản phẩm store tương ứng; hiển thị giá hợp lệ của kênh. Server không tin giá, số ngày hoặc maxKids gửi từ app.
2. Backend tạo purchase intent/order gắn parent_id lấy từ phiên; snapshot sản phẩm, giá, tiền tệ, quyền lợi và phiên bản. Khóa chống tạo trùng theo thao tác mua.
3. App mở checkout nhà cung cấp/store; người dùng có thể hủy hoặc rời ứng dụng.
4. Backend xác minh receipt/token hoặc webhook có chữ ký, danh tính đơn, sản phẩm, tài khoản, số tiền/tiền tệ khi kênh có cung cấp. Callback trên app chỉ dùng cập nhật màn hình, không tự cấp Plus.
5. Trong một giao dịch database: đánh dấu giao dịch đã xác minh, ghi kỳ quyền học, cập nhật subscriptions hiện hành và ghi log. Unique transaction/event ngăn cấp quyền lặp.
6. Nếu database lỗi sau khi nhà cung cấp thu tiền: lưu/nhận lại sự kiện, retry an toàn, job đối soát phát hiện giao dịch chưa cấp quyền. Không yêu cầu phụ huynh trả tiền lần hai.
7. App refresh/poll có giới hạn hoặc nhận tín hiệu cập nhật, rồi đọc lại quyền từ server. Reload hoặc cài lại app vẫn lấy được quyền đã mua.
8. Webhook gia hạn/hủy/hoàn tiền được lưu và xử lý theo thời điểm hiệu lực. Sự kiện cũ đến muộn không được ghi đè trạng thái mới; khi mâu thuẫn truy vấn nhà cung cấp.

Đơn hàng: pending → processing → paid; hoặc canceled/expired/failed; trạng thái refund có thể bổ sung theo kênh. Payment có vòng đời riêng: pending/succeeded/failed/refunded. Subscription có vòng đời quyền riêng: trial/active/grace/expired/revoked theo trạng thái provider. Không dùng một cột status để đại diện cả ba.

Chỉ backend được ghi trạng thái trả tiền và cấp quyền. Admin hỗ trợ có thể yêu cầu kiểm tra lại, cấp bù có lý do; không tự sửa giao dịch thất bại thành đã thanh toán. Đối với store, theo dõi acknowledgement/finish và thông báo gia hạn đúng giao thức nhà cung cấp trong giai đoạn tích hợp.

Các API dự kiến: get_catalog, get_effective_entitlements, create_purchase_intent, verify_purchase, restore_purchases, get_order_status, payment_webhook, reconcile_payments. Đây là hợp đồng thiết kế, chưa phải API hiện có. Edge Functions phù hợp để giữ secret và tích hợp provider; giao dịch dữ liệu thực hiện qua hàm database có quyền giới hạn. [Supabase Edge Functions](https://supabase.com/docs/guides/functions).

## 5. Rà soát 19 bảng Supabase đang có

| Bảng hiện tại | Hướng xử lý | Phần cần sửa/kết nối |
|---|---|---|
| parents | Giữ | Gắn đúng auth.users sau khi xử lý dữ liệu seed mồ côi; tên hiển thị nếu cần; thay PIN thô; không thu SĐT nếu chưa có mục đích/lưu trữ tương ứng |
| kid_profiles | Giữ, sửa ưu tiên P0 | Bỏ policy authenticated USING(true); sở hữu/admin hợp lệ; archive/trạng thái hoạt động khi hết gói; index và CHECK sao ≥0, thời gian hợp lệ |
| topics | Giữ | Nhiều chủ đề/lớp, order và published; sửa fetch maybeSingle theo grade vì một lớp có thể có nhiều chủ đề |
| lessons | Giữ | Content access free/plus, published/version, mục tiêu/kỹ năng; không lưu tiến độ cá nhân vào bản ghi giáo trình |
| questions | Giữ | Payload validation theo type, độ khó, version; published access gắn bài; đáp án không phát tán công khai với bài trả phí |
| kid_progress | Giữ, nối app | UNIQUE(kid_id,lesson_id), upsert đúng conflict target; best_accuracy/attempts và quy tắc hoàn tất; server ghi từ session |
| kid_streaks | Giữ, sửa | Đọc về app, cập nhật một lần/ngày; quy tắc 21h theo múi giờ; chống ghi streak tùy ý |
| practice_garden_logs | Giữ, sửa | Một lần chốt/phiên, session/idempotency ID; đủ số câu theo nghiệp vụ; không ghi nhiều log tổng lũy kế mỗi câu |
| tournaments | Giữ | Thêm số nhóm; đổi UNIQUE(grade,week_code) thành (grade,week_code,group_number); chốt kỳ/nhóm đầy |
| tournament_members | Giữ | Nối nhóm thật, kiểm tra lớp, giới hạn thành viên; điểm do server, rank tính từ XP thay vì client tự gửi |
| mascot_items | Giữ, nối app | Catalog hoạt động, giá sao server quản lý; đồ đã sở hữu vẫn có thể trang bị nếu ngừng bán |
| kid_inventory | Giữ, nối app | Chỉ cấp sau giao dịch mua thưởng hợp lệ; revoke đường INSERT/DELETE tùy ý từ client |
| kid_equipment | Giữ, nối app | Kiểm tra quyền sở hữu và đúng slot khi trang bị; chuyển dữ liệu từ avatar_id nếu khớp catalog |
| study_sessions | Giữ, nối app | ended_at/status, thời lượng active, lesson version, client_session_id UNIQUE; chốt thưởng server |
| question_attempts | Giữ, nối app | Số lần thử/đáp án/gợi ý/thời gian; kiểm tra question thuộc bài của session; chống ghi trùng; tự luận cần phản hồi có cấu trúc |
| admins | Chuyển đổi dần | Hiện trùng chức năng với user_roles; backfill role bằng UID xác thực; sau chuyển không dùng email để cấp admin |
| user_roles | Giữ làm nguồn vai trò | Bootstrap admin có kiểm soát; parent/admin/moderator; client chỉ đọc role của mình, không tự nâng quyền |
| subscriptions | Giữ làm quyền hiện hành | Một dòng/parent tương thích app; thêm plan/source/period reference, trial marker nếu cần; quyền tính theo status và hạn thực tế |
| subscription_logs | Giữ, sửa | Append-only, ghi nguồn order/payment/admin, trước/sau, lý do; parent chỉ đọc của mình; không cho admin sửa/xóa lịch sử tùy ý |

View v_leaderboard: dùng tập trường nickname/điểm/rank cần thiết, giới hạn phạm vi giải phù hợp. Không mở quyền đọc cả kid_profiles để JOIN leaderboard. Rà hành vi view mặc định chạy theo quyền owner; thiết kế RPC/view có chủ ý và thử bằng user thật. [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security).

Các policy đọc topics/lessons/questions hiện là public. Khi bán nội dung, chỉ khóa nút ở UI không đủ: vẫn có thể đọc bài trả phí qua API. Cho phép đọc metadata catalog đã xuất bản; payload học chỉ trả khi có quyền phù hợp. Tách đáp án kiểm chứng phía server nếu cần chống gian lận XP/BXH; không trộn public preview với toàn bộ bài và đáp án.

## 6. Bảng mới cần cho bán gói

Thiết kế MVP theo fixed Basic/Plus và chu kỳ tháng/năm, tránh xây hệ thương mại tổng quát quá sớm. Dùng UUID phù hợp hệ thống đang có, timestamptz cho thời điểm, bigint tiền theo đơn vị nhỏ nhất của currency, không dùng double cho tiền; FK và index theo đường truy vấn.

| Bảng mới | Trường/quan hệ chính đề xuất | Ràng buộc và quyền |
|---|---|---|
| learning_plans | id, code UNIQUE, name, tier, description, published, created_at | Catalog logic Basic/Plus; chỉ admin đúng quyền sửa; parent đọc đã xuất bản |
| plan_prices | id, plan_id, version, billing_period, amount_minor, currency, channel, provider_product_id, benefits_snapshot, published, valid_from/to | Giá và quyền lợi đã bán bất biến; max_kids/quota dùng kiểu và validation rõ ràng trong snapshot; UNIQUE mapping sản phẩm theo provider/channel; không lấy snapshot do client tự gửi |
| orders | id, parent_id, plan_price_id, amount_minor, currency, snapshot, status, idempotency_key, created_at, paid_at | Một sản phẩm/đơn MVP nên chưa cần order_items; UNIQUE(parent_id,idempotency_key); parent đọc đơn mình; backend ghi |
| payments | id, order_id, provider, external_transaction_id, status, amount_minor, currency, verified_at, refunded_at, purchase_chain_reference | Một đơn có thể có nhiều lần thử; UNIQUE(provider,external_transaction_id) khi có mã; token/receipt lưu riêng hoặc schema private, không trả raw secret qua API |
| payment_events | id, provider, external_event_id, transaction_reference, occurred_at, received_at, processing_status, retry_count, last_error, processed_at | UNIQUE(provider,external_event_id); raw payload hạn chế/private và có retention; chỉ backend đọc/ghi; chỉ số cho pending retry |
| subscription_periods | id, parent_id, plan_price_id, payment_id nullable, source, starts_at, ends_at, status, granted_by nullable, reason | Lịch sử từng kỳ quyền, cả store/admin/trial; UNIQUE theo nguồn cấp chống nhân đôi; nguồn hiện hành cho projection subscriptions; không giới hạn một kỳ lịch sử/parent |

Không hard-delete đơn, payment, kỳ quyền hoặc giá đã có giao dịch. Catalog ngừng bán bằng trạng thái; order lưu snapshot để lịch sử không đổi khi admin chỉnh tên/giá. Refund nhiều lần/partial refund nếu được hỗ trợ sẽ cần bảng refunds riêng ở giai đoạn sau; MVP có thể giới hạn full refund theo provider.

Ràng buộc thêm: FK order→parent/price, payment→order, period→parent/payment; amount≥0; thời gian kết thúc sau bắt đầu; currency hợp lệ; phép chuyển status được kiểm soát. Provider product ID cần scope theo nền tảng và loại sản phẩm/base plan; cấu trúc mapping chi tiết chốt theo kênh mua đã chọn.

Index tối thiểu dự kiến: orders(parent_id,created_at DESC), payments(order_id), subscription_periods(parent_id,starts_at DESC), kỳ đang hiệu lực theo truy vấn thực tế, payment_events(processing_status,received_at), plan_prices(plan_id,channel,published). Không tạo index trùng khóa unique sẵn có.

Bảng bổ sung cho giai đoạn hoàn thiện: skills và question_skills để báo cáo đúng kỹ năng; admin_audit_logs append-only cho nội dung/role/catalog; ai_scan_requests cho quota/trạng thái OCR khi tích hợp AI. notifications/support_tickets chỉ thêm nếu đã có luồng sử dụng cụ thể. Không tạo bảng mới thay study_sessions/inventory đang tồn tại.

Quan hệ chính: parent → orders → payments → subscription_periods; learning_plans → plan_prices → orders; subscription_periods → subscriptions hiện hành. Quyền học của bé được tính qua parent_id và trạng thái hồ sơ hoạt động; chưa cần bảng quyền riêng cho mỗi bé trong MVP gia đình.

## 7. Phân quyền và tính toàn vẹn

- Parent chỉ đọc/sửa thông tin gia đình được phép; đọc gói, đơn, quyền hiện hành và lịch sử của mình. Tạo order qua backend; không tự update paid, period, max_kids, XP hoặc inventory.
- Student dùng phiên gia đình nhưng chỉ có giao diện học. Hành động mua, đổi PIN, xóa bé, đổi thông tin tài khoản cần xác thực lại phù hợp; nếu cần ràng buộc chế độ học sinh phía server, thiết kế session/phạm vi quyền riêng, không chỉ dựa vào một bool trong Provider.
- Admin vận hành theo capability; moderator chỉ nội dung. Audit nội dung, cấp gói, đổi role có actor/reason/time/before/after. Secret và receipts private không xuất hiện trong dashboard thông thường.
- Backend payment có quyền đúng phạm vi, xác minh chữ ký/token, chống replay, khóa theo đơn/parent khi cấp kỳ. Các RLS không cho client tự thực hiện nhánh đặc quyền.
- purchase_item cần rà thứ tự lock/kiểm tra sở hữu trong hai yêu cầu đồng thời. Trigger giới hạn bé cần khóa chung theo parent; hai insert đồng thời không được vượt slot.
- get_effective_entitlements và enforcement API dùng chung logic; check_max_kids_limit xét status/hạn/source thay vì chỉ max_kids. Job cập nhật expired phục vụ UI/notification, không thay thế kiểm tra thời hạn ngay khi truy cập.

## 8. Cách nâng cấp database đang chạy

1. Kiểm kê schema/policy/function thực tế và lịch sử migration, đếm dữ liệu mồ côi/seed/demo, chụp snapshot/backup phục hồi được trước thay đổi cấu trúc.
2. Tạo migration mới theo quy trình CLI; không sửa migration đã chạy rồi kỳ vọng Cloud tự cập nhật, không reset database hoặc chạy lại seed hàng loạt trên dữ liệu người dùng.
3. Hotfix policy kid_profiles và luồng đọc gia đình; áp dụng thay đổi view/API leaderboard cùng đợt để không làm hỏng BXH. Bỏ bypass auth/OTP trước cho dùng dữ liệu thật.
4. Thêm catalog/commerce và cột nullable tương thích trước. Backfill Basic/Plus đang có thành quyền có nguồn legacy_admin; giữ ngày hết hạn và điều tra trước những dòng vĩnh viễn. Không giả lập lịch sử thanh toán cho quyền cũ.
5. Backfill role admin bằng UID đã xác minh; xử lý parent seed không có auth.users trước khi bổ sung lại FK. Chuyển avatar_id sang inventory/equipment chỉ khi có mapping chắc chắn; không tự thu sao lại.
6. Triển khai API và app đọc quyền mới sau feature flag; đối chiếu quyền cũ/mới, bật checkout sandbox, kiểm tra lỗi và retry.
7. Bổ sung constraint/siết grant sau backfill; chỉ dừng luồng cũ khi phiên bản app hỗ trợ. Giữ khả năng tắt checkout mà người đã mua vẫn được học.
8. Kiểm thử restore và rollout staging → nhóm thử nghiệm → toàn bộ. Sửa sai bằng migration tiếp theo; không rollback mù bằng cách xóa bảng có đơn/payment.

## 9. Backlog và thứ tự triển khai

Ước lượng cho nhóm 4 người làm đều: 8–10 tuần cho MVP có một kênh thanh toán thật, chưa bao gồm toàn bộ mở rộng AI/offline. Quy trình đăng ký tài khoản merchant/store, duyệt sản phẩm và kiểm định nội dung là phụ thuộc ngoài nhóm. Có thể làm catalog/UI admin đồng thời với ổn định nền tảng, nhưng chỉ bật bán sau khi dữ liệu học và quyền truy cập đạt tiêu chí.

| Giai đoạn | Công việc đầu ra | Nghiệm thu |
|---|---|---|
| 0 — Chốt sản phẩm, 2–3 ngày | Gói/quyền lợi, kênh phát hành và thanh toán, chu kỳ, trial, hết hạn, prototype theo role | Không có quyền lợi chưa làm; xác định được người mua/gia đình sử dụng/nguồn quyền |
| 1 — Nền tảng, tuần 1–2 | Auth thật, PIN, state theo tài khoản, RLS, CRUD bé, fix tests/analyze, Android release | A không đọc B; sai auth không vào app; đổi tài khoản sạch dữ liệu; release có mạng |
| 2 — Vòng học và quyền, tuần 3–4 | Progress/streak/session/accuracy/thưởng chuẩn, entitlement API, free/plus content access, giới hạn học | Mua quyền có đối tượng sử dụng thật; bài trả phí không đọc lén qua API; mở lại không mất bài |
| 3 — Bán gói sandbox, tuần 5–6 | 6 bảng commerce, Edge Functions, store/cổng sandbox, catalog/checkout/history/restore, admin orders | Thành công/hủy/pending/duplicate callback/refund đều đúng; tiền đã thu không cấp hai lần |
| 4 — Vận hành, tuần 7–8 | Đối soát/retry, audit, phân trang admin, báo cáo thật, nối tủ đồ và nhóm đấu trường | Đơn lỗi truy được; trạng thái quyền khớp đa thiết bị; giới hạn nhóm và mua đồ đồng thời đúng |
| 5 — Pilot và release, tuần 9–10 nếu cần | Nội dung đã duyệt, QA thiết bị, thanh toán thật quy mô thử nghiệm, hướng dẫn hỗ trợ | Luồng xuyên suốt ổn định; đối soát khớp; không bán tính năng mô phỏng |

Sau MVP: offline Plus đầy đủ, OCR/AI thật, luyện tập thích ứng, CMS nâng cao, coupon/referral, khóa học theo lớp/chủ đề. Bán Plus không phải lý do trì hoãn sửa dữ liệu hoặc đưa AI mô phỏng vào quyền lợi thu phí.

Phân công đề xuất: người 1 Auth/Parent UX; người 2 Learning/Student UX và dữ liệu học; người 3 Supabase/RLS/Commerce Backend; người 4 Commerce UI/Admin và QA/CI. Payment backend và quyền truy cập cần được người khác trong nhóm review; không tạo task/gửi giao việc tự động trong phiên lập kế hoạch này.

## 10. Bộ tiêu chí hoàn thành MVP

1. Phụ huynh mới đăng ký, xác minh và tạo được bé đầu tiên; không nhận hồ sơ/demo/progress sẵn.
2. Phụ huynh mua một gói sandbox/thật trên kênh đã chọn, thấy đơn và ngày hiệu lực, đổi máy/đăng nhập lại vẫn đúng quyền.
3. Cùng giao dịch gửi xác minh/webhook 5 lần vẫn chỉ ghi nhận một payment và cấp một kỳ quyền; hai lần mua hợp lệ khác nhau xử lý đúng chính sách.
4. Hủy checkout, thanh toán pending, webhook đến trước callback, mất mạng sau thu tiền và sự kiện đến sai thứ tự có trạng thái rõ và khôi phục được.
5. Hủy gia hạn giữ quyền đến hết kỳ; refund/revoke/hết hạn điều chỉnh quyền đúng; không xóa dữ liệu các bé.
6. Parent A không đọc bé/đơn/receipt của B; moderator không đổi gói/role; client không tự tăng sao, đặt paid hoặc đọc nội dung Plus ngoài quyền.
7. Bé học một phiên: sai/đúng/hết tim/ôn tập/quay lại/hoàn tất; progress, accuracy, thời lượng và thưởng khớp, không thưởng lặp.
8. Streak đúng cùng ngày/ngày kế/gián đoạn/mốc 21h; screen time foreground/background/sang ngày đúng.
9. Admin tra được lịch sử đơn và lần cấp quyền, tạo giá mới không làm biến đổi đơn cũ, cấp bù có lý do và audit.
10. Analyze/test/SQL security test/build release đạt; chạy luồng trên thiết bị thật. Kết quả cũ trong phiên đánh giá trước là 22 lint issues, 1 widget test đạt và 2 thất bại; chưa chạy lại vì phiên này chỉ lập kế hoạch.

Chỉ số pilot: tỷ lệ từ chọn gói đến trả tiền thành công; tỷ lệ giao dịch đã xác minh nhưng chưa cấp quyền; thời gian cấp quyền; số lỗi đối soát; tỷ lệ hoàn thành bài và khôi phục phiên; tỷ lệ phụ huynh xem báo cáo. Đo baseline trước rồi đặt mục tiêu, không dùng chỉ số giả để quảng bá.

Các quyết định cần chốt tại giai đoạn 0: Android/iOS/web/kênh nội bộ ưu tiên; provider thanh toán; giá và kỳ; danh sách bài Basic; số bé/quyền lợi; trial; xử lý hạ gói; yêu cầu tự luận; thời điểm đưa AI vào gói. Những lựa chọn này chưa ngăn việc bắt đầu sửa Auth/RLS/state và hoàn thiện vòng học.
