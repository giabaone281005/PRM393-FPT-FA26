# Kịch bản demo MathLingo — Phụ huynh, bé và admin

Dành cho buổi demo **22/10/2026**. Thời lượng đề xuất **12–15 phút**. Thanh toán trong kịch bản là **mô phỏng, không thu tiền thật**, có lưu lịch sử trên Supabase và cấp quyền Plus demo.

## Chuẩn bị trước khi trình bày

1. Cài bản APK ứng dụng cuối cùng tại [app-debug.apk](D:/DEMO/PRM391/build/app/outputs/flutter-apk/app-debug.apk). Không dùng APK của integration test để demo thủ công.
2. Dùng mạng ổn định. Chuẩn bị hai thiết bị hoặc hai phiên độc lập nếu muốn cho thấy dữ liệu thay đổi giữa các vai trò; hai cửa sổ dùng chung phiên đăng nhập không thay thế hai tài khoản độc lập.
3. Tài khoản thử đã đổi tên cho dễ nhập: `parent@demo.test` cho phụ huynh, `admin@demo.test` cho admin. Mật khẩu xem trong [build/demo-qa.json](D:/DEMO/PRM391/build/demo-qa.json): `QA_PASSWORD` và `QA_ADMIN_PASSWORD`. `QA_OTHER_EMAIL` là gia đình đối chiếu để kiểm tra cách ly dữ liệu. File chứa mật khẩu, đã bị Git bỏ qua. Hai tài khoản đã xác minh sẵn; địa chỉ thử nghiệm không nhận email.
4. Tài khoản phụ huynh QA đã có bé và bài học thử; sau kiểm thử có thể đã có Plus và giao dịch demo. Muốn trình bày Basic → Plus từ đầu, dùng một tài khoản phụ huynh mới đã xác minh email. Không cần xóa giao dịch cũ để chạy lại demo.
5. PIN của phụ huynh QA là trường `QA_PIN` trong cùng file cấu hình bị Git bỏ qua. Khi dùng tài khoản của bạn, nhập đúng PIN bạn đã tạo. Không dùng nhãn PIN mặc định từ phiên bản app cũ.
6. Chế độ demo trên server có thời hạn: hiện bật đến khoảng **01:23 ngày 23/10/2026 (UTC+7)**. Sau thời điểm này nút tạo giao dịch demo sẽ ẩn khi tải lại. Lịch sử giao dịch vẫn được giữ; không tự gia hạn quyền demo sau ngày hết hạn gói.

## Phần 1 — Phụ huynh tạo và quản lý gia đình (2 phút)

| Thao tác trên app | Điều cần chỉ cho thầy | Lời dẫn gợi ý |
|---|---|---|
| Đăng nhập phụ huynh | Vào giao diện học của bé, dữ liệu gia đình được tải từ hệ thống | “Một phụ huynh quản lý nhiều hồ sơ bé; mỗi bé giữ tiến độ riêng.” |
| Nếu là tài khoản mới: Thêm bé → đặt PIN → nhập biệt danh/lớp → tạo | Tạo hồ sơ có kiểm tra quyền và giới hạn gói | “Basic bắt đầu với một bé; thao tác quản lý cần xác thực phụ huynh.” |
| Biểu tượng khóa → nhập PIN → Các bé | Danh sách hồ sơ và quyền hiện tại | “Đăng nhập tài khoản và mở cổng phụ huynh là hai bước riêng.” |
| Sửa biệt danh của bé → lưu | Thông tin được lưu trên hệ thống; phiên còn lại cập nhật khi nhận sự kiện | “Đây là dữ liệu lưu thật, đăng nhập lại vẫn còn.” |
| Thời gian học → chọn giới hạn → lưu | Giới hạn theo ngày, có xác thực trước khi sửa | “Thời lượng được ghi nhận qua phiên học, không chỉ là số đếm trên giao diện.” |

## Phần 2 — Bé học và phụ huynh theo dõi (4 phút)

1. Chọn **Về chế độ học sinh**. Cổng phụ huynh bị khóa.
2. Mở **Trang chủ → bài đang học** hoặc **Bài học → chủ đề → bài**. Nếu dùng QA, chọn chủ đề **QA Hành trình cộng**.
3. Xem lý thuyết, vào câu hỏi. Trả lời một câu sai để minh họa phản hồi, rồi trả lời đúng. Không cố bấm “nhận thưởng” trước khi hoàn tất yêu cầu bài.
4. Chọn **Lưu kết quả và nhận thưởng**. Chỉ khi server xác nhận mới trình bày kết quả hoàn thành.
5. Mở lịch sử học của bé: xem phiên, câu đã trả lời, độ chính xác và kết quả. Ôn lại bài đã hoàn thành để giải thích không nhận thưởng lần đầu hai lần.
6. Ở phiên phụ huynh, mở **Tổng quan**, chọn đúng bé: xem số bài hoàn thành, phút học, bài gần nhất và dữ liệu bảy ngày.

**Lời dẫn:** “Kết quả trả lời, thời gian học và báo cáo cùng lấy từ dữ liệu phiên trên server. Khi tắt app hoặc đăng nhập lại, lịch sử không phụ thuộc bộ nhớ của màn hình.”

**Lưu ý thời gian:** app gửi nhịp học đang hoạt động khoảng 20 giây/lần; báo cáo có thể cập nhật sau khi server nhận nhịp tiếp theo. Không gọi mọi số liệu là thay đổi ngay từng giây. Khi hiện dưới một phút, báo cáo có thể ghi `<1` thay vì một phút tròn.

## Phần 3 — Thanh toán mô phỏng có lưu lịch sử (3 phút)

1. Phụ huynh mở khóa bằng PIN → **Gói học → Xem gói và lịch sử mua**.
2. Chỉ ra gói đang dùng, giá và kỳ hạn lấy từ danh mục. Hướng dẫn mua dựa trên trạng thái Basic/Plus, dùng thử và đơn đang chờ.
3. Chọn **Thanh toán demo · không thu tiền** dưới gói muốn trình bày. Nút này tạo giao dịch demo riêng; không cần mở MoMo hoặc ngân hàng.
4. Trên màn **Thanh toán mô phỏng**, chỉ ra giá trị mô phỏng và mã đơn. Chọn **Giả lập thanh toán thành công**.
5. Chờ thông báo **Đã thanh toán mô phỏng thành công**. Chỉ ra mã giao dịch bắt đầu bằng `DEMO-`.
6. Về màn gói học, kéo xuống **Lịch sử thanh toán mô phỏng**. Giao dịch có trạng thái đã thanh toán, thời điểm, mã đơn và mã giao dịch. Quyền Plus được tải lại từ server.
7. Đăng nhập lại hoặc dùng phiên phụ huynh thứ hai để kiểm tra lịch sử vẫn còn. Với Basic → Plus, có thể thêm hồ sơ bé thứ hai sau khi quyền được cập nhật.

**Lời dẫn:** “Đây là bước thanh toán giả lập để demo nghiệp vụ. Giao dịch được lưu và cấp quyền demo thật trên hệ thống, nhưng không thu tiền và không ghi thành doanh thu MoMo/VNPay.”

Nếu tài khoản đã có Plus không thời hạn, nút mua bị khóa theo quyền gói. Chọn tài khoản Basic hoặc Plus có thời hạn để trình bày thanh toán. Nếu giao dịch demo đang chờ, tiếp tục ngay tại lịch sử demo.

## Phần 4 — Admin vận hành và trả lời hỗ trợ (3 phút)

| Bước | Thao tác | Kết quả cần thấy |
|---|---|---|
| 1 | Đăng nhập tài khoản admin | Màn hình quản trị theo quyền server |
| 2 | Mở quản lý gia đình, tìm tài khoản phụ huynh demo | Đúng bé, thông tin gói và dữ liệu đã lưu |
| 3 | Mở Gói & giao dịch / Gói học & đơn hàng | Xem giao dịch thật và phần **Lịch sử thanh toán mô phỏng** riêng |
| 4 | Chỉ ra giao dịch `DEMO-` vừa thực hiện | Đúng mã phụ huynh, trạng thái và giá trị mô phỏng; không có thao tác hoàn tiền ngân hàng cho demo |
| 5 | Phụ huynh gửi yêu cầu ở Hỗ trợ gia đình | Admin thấy yêu cầu của gia đình |
| 6 | Admin phản hồi và hoàn tất | Phụ huynh nhận phản hồi và thông báo của chính gia đình |
| 7 | Mở CMS, xem chủ đề/bài học hoặc bản nháp | Giới thiệu quy trình biên soạn và xuất bản; chỉ sửa nội dung QA đã chuẩn bị nếu cần thao tác ghi |

Không thực hiện hoàn tiền VNPay, cấp quyền admin cho tài khoản thật hoặc thay đổi bài đang dùng trong buổi demo.

## Phần 5 — Chứng minh cách ly và khả năng phục hồi (1–2 phút, tùy thời gian)

- **Hai gia đình:** đăng nhập tài khoản `QA_OTHER_EMAIL`; không thấy bé, hỗ trợ hoặc giao dịch demo của phụ huynh đầu tiên.
- **Hai phiên cùng phụ huynh:** mở PIN ở phiên B; phiên A vẫn thao tác được với PIN đã mở của chính phiên A. Thoát cổng ở B không khóa A. Đổi PIN sẽ thu hồi các phiên mở khóa trước đó.
- **Mất mạng:** thông báo đang dùng dữ liệu gần nhất hoặc chờ đồng bộ; không tuyên bố thưởng/Plus đã lưu nếu server chưa xác nhận. Kết nối lại và kiểm tra lịch sử sau đồng bộ.
- **Làm mới:** nếu một màn chưa cập nhật, dùng nút tải lại. Kênh realtime có cơ chế tải lại dự phòng khoảng 30 giây khi app ở foreground.

## Những điều nên nói đúng khi được hỏi

| Câu hỏi | Câu trả lời |
|---|---|
| “Toàn bộ dữ liệu realtime chưa?” | “Dữ liệu gia đình, gói, phiên học, thông báo, hỗ trợ và giao dịch demo đã được nối cập nhật qua sự kiện, kèm tải lại dự phòng. Một số dữ liệu vẫn tải khi mở màn/làm mới; cài đặt giao diện và âm thanh lưu cục bộ.” |
| “Có trả tiền thật chưa?” | “Buổi này dùng thanh toán mô phỏng có lịch sử riêng. Merchant thật chưa nghiệm thu.” |
| “Bấm hai lần có cấp gói hai lần không?” | “Cùng một giao dịch được xác nhận lại thì server trả kết quả cũ, không cộng thêm một kỳ Plus.” |
| “Hết Plus có mất dữ liệu không?” | “Hồ sơ và lịch sử được giữ; Basic học với một bé được chọn.” |
| “Đổi PIN khác đổi mật khẩu thế nào?” | “Mật khẩu đăng nhập tài khoản; PIN bảo vệ chức năng phụ huynh trong phiên sử dụng.” |

Đối chiếu kết quả đã chạy và các giới hạn trong [báo cáo kiểm thử](D:/DEMO/PRM391/DEMO_TEST_REPORT_20261021.md), và sơ đồ chi tiết trong [UpdateUserFlow.md](D:/DEMO/PRM391/UpdateUserFlow.md).
