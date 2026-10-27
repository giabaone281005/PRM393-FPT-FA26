# Rà soát thông báo người dùng

Phạm vi: các luồng UI hiện có trong codebase Flutter, 26/10/2026. Giữ theme REA,
không hiển thị raw exception, SQL, response body, khóa/token hoặc stack trace.

## Quy tắc

- Chỉ báo thành công sau kết quả thực tế: phiên Auth tồn tại, RPC sao lưu trả
  receipt, ghi cấu hình bảo mật thành công hoặc ghi cục bộ thành công.
- Không suy đoán nguyên nhân cho lỗi bất ngờ. `friendlyError` dùng fallback trung
  tính khi không có type/code tin cậy; không gán mọi lỗi cho mạng hoặc mật khẩu.
- Dùng mã lỗi ổn định của Auth/PostgREST/HTTP, không phân tích chuỗi lỗi server.
- Nêu hành động tiếp theo, giữ dữ liệu người dùng đã nhập khi thao tác thất bại.
- `AppNotice` có icon, nội dung dễ đọc và live region; trạng thái không chỉ dựa vào màu.

## Những luồng đã rà và chỉnh

| Luồng | Thông báo / điều kiện |
|---|---|
| Đăng nhập | Tách sai email/mật khẩu, email chưa xác nhận, phiên hết hiệu lực, tài khoản bị khóa và dịch vụ 5xx. Không chẩn đoán sai mật khẩu từ lỗi server. |
| Đăng ký | Có session thì vào app; không có session thì nhập mã. Không khẳng định tài khoản mới đã tạo hoặc email đã được chuyển đến hộp thư, vì Supabase có thể che giấu đăng ký lặp. |
| Mã email | Sai định dạng không gọi server. `otp_expired` hiển thị “chưa đúng hoặc đã hết hạn”, vì server không phân biệt hai trường hợp này. Mã đúng có session mới cho đăng nhập và tự lưu. |
| Gửi lại mã | Cooldown 60 giây, giới hạn server vẫn có hiệu lực. Thành công chỉ có nghĩa yêu cầu được xử lý. Giữ mã đang nhập nếu gửi lại thất bại. |
| Cloud | Không gọi thiếu quyền là tài khoản bị khóa. Không gọi mọi exception là mất mạng. Lỗi lưu liên kết trên máy không khẳng định cloud đã lưu. Bản local được giữ khi sao lưu thất bại. |
| Trạng thái sao lưu | Binding revision 0 là đang chờ sao lưu; receipt revision >0 mới hiển thị đã có bản cloud. Đã đăng nhập nhưng chưa chọn hồ sơ được hướng dẫn chọn hồ sơ. |
| Khôi phục | Chỉ báo đã tải về sau khi lưu hồ sơ riêng và liên kết xong. Trường hợp chưa hoàn tất giữ các hồ sơ hiện có. |
| Chat Koji | Giữ nguyên lý do an toàn từ engine (khóa, quyền, hạn mức, timeout...). Câu hỏi đang nhập vẫn ở đó để thử lại. Lỗi không xác định dùng thông báo trung tính. |
| Engine | Phân biệt HTTP 401, 403, 404, 413, 429, 5xx và redirect. Không hiển thị raw response. Cấu hình không đọc được không khẳng định thiết bị đang khóa. |
| Form engine | Thông báo validation do app viết được phép hiển thị. Lỗi `Uri.parse` dùng hướng dẫn URL thân thiện thay cho lỗi parser. |
| Chạy mã | Lỗi validation tách khỏi lỗi bất ngờ. Exit code 0 mới báo chạy xong; lỗi compile/runtime là chưa hoàn tất; không có exit code thì chỉ báo đã nhận kết quả. Kết quả ghi tên engine thực sự đã chạy. Stdout/stderr/compile output là nội dung cần thiết của môi trường lập trình. |
| Bài học | Phân biệt thay đổi hồ sơ, thí nghiệm chưa hoàn thành và lỗi lưu kết quả. Không yêu cầu làm lại bài chỉ vì ghi thiết bị thất bại. `LocalLearningFailure` giữ tương thích StateError. |
| Lưu ngay ở Hồ sơ | Báo “Đã lưu tiến độ trên thiết bị”, không ngụ ý đã sao lưu cloud. |
| Cài đặt giao diện | UI chỉ cập nhật sau ghi thành công; thất bại báo chưa lưu và cho thử lại. |
| Đăng xuất | Trong lúc xử lý yêu cầu trước đó, thông báo chờ và chọn lại thay vì im lặng bỏ thao tác. |

Các feedback học tập hiện có (`invalid-state`, gợi ý sửa thí nghiệm, hoàn thành và
XP cá nhân) tiếp tục dùng evaluator/catalog hiện có, không đổi luật chấm điểm.
Widget quiz/dashboard mới vẫn là component nhận dữ liệu, chưa phải đánh giá server.

## Kiểm tra và giới hạn

`test/app_messages_test.dart`: lỗi bất ngờ không bị gán nhầm nguyên nhân, bí mật
trong diagnostic không xuất hiện trong UI, nguyên nhân Auth/HTTP/PostgREST khác nhau.
`test/cloud_backup_test.dart`: OTP, resend/cooldown, lỗi hết hạn, session, auto-backup,
restore, offline và UI 320px với chữ lớn.
`test/auth_repository_test.dart`: wire protocol thật của SDK qua mock HTTP, đúng
type `email` khi verify và `signup` khi resend.
`test/chat_layout_test.dart`: lý do lỗi engine và draft được giữ.

Lỗi native/OS, sự cố provider thật và hộp thư thật không thể suy ra chỉ từ test
mock. Khi server không cung cấp mã lỗi đủ rõ, app chủ động báo chưa hoàn tất,
không bịa ra nguyên nhân cụ thể. Email template hosted cần được áp dụng riêng;
xem `supabase/templates/README.md`.
