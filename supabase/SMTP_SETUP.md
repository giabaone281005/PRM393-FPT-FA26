# Gmail SMTP cho đăng ký MathLingo

## Phạm vi và trạng thái

Dự án: `seoswmcldwwytdrfrrrb`. Đăng ký hiện gọi Supabase Auth, mở màn xác minh rồi kiểm tra OTP/liên kết bằng server. SMTP phải nằm ở Supabase Auth; không thêm mật khẩu Gmail hoặc thư viện gửi SMTP vào ứng dụng Flutter.

**Đã triển khai SMTP và nhận email thật ngày 21/10/2026.** Người dùng xác nhận cho phép lưu mật khẩu ứng dụng vào cấu hình SMTP của project này. Địa chỉ gửi là `Khazim2810@gmail.com`, tên gửi MathLingo, máy chủ `smtp.gmail.com`, cổng 587. Credential chỉ được nhập/lưu trong Supabase, không ghi vào mã Flutter, config client hoặc tài liệu.

Mẫu Confirm sign up trên Cloud đã đổi sang subject `Xác minh email MathLingo` và nội dung OTP tiếng Việt từ file có sẵn trong repository. Đã tải lại trang và xem trước để xác nhận bản lưu trên máy chủ, không chỉ sửa biểu mẫu chưa lưu.

## Cấu hình trên Supabase Cloud

Mở [SMTP Settings](https://supabase.com/dashboard/project/seoswmcldwwytdrfrrrb/auth/smtp), bật Custom SMTP và điền:

| Trường | Giá trị |
|---|---|
| Sender email | `Khazim2810@gmail.com` |
| Sender name | MathLingo |
| Host | `smtp.gmail.com` |
| Port | `587` — STARTTLS |
| Username | `Khazim2810@gmail.com` |
| Password | Mật khẩu ứng dụng Google của chính tài khoản Gmail đó; nhập trực tiếp, bỏ khoảng cách chia nhóm |

Không thay bằng mật khẩu đăng nhập Google. Không ghi mật khẩu ứng dụng vào repo, `config/app.json`, log hoặc ảnh bàn giao. Không bật tự động xác nhận email để né lỗi gửi thư.

Trong [Email Templates](https://supabase.com/dashboard/project/seoswmcldwwytdrfrrrb/auth/templates), chọn **Confirm signup**:

- Subject: `Xác minh email MathLingo`.
- Body: nội dung [confirmation.html](D:/DEMO/PRM391/supabase/templates/confirmation.html).
- Giữ nguyên `{{ .Token }}` để Supabase tự sinh mã thật. Mẫu hiện tại ưu tiên nhập mã trong ứng dụng để dùng được cả khi đọc thư trên máy tính. Không điền mã mẫu cố định.

Trong **Sign In / Providers → Email**, bật xác nhận email cho đăng ký. Trong [URL Configuration](https://supabase.com/dashboard/project/seoswmcldwwytdrfrrrb/auth/url-configuration), thêm chính xác `mathlingo://auth-callback` vào redirect allowlist, giữ các URL đang được sử dụng. Không thêm wildcard hoặc thay Site URL hiện có theo suy đoán.

Mã có thể nhập trên mọi nền tảng. Android đã đăng ký scheme `mathlingo`; iOS hiện chưa có URL scheme tương ứng nên chưa coi liên kết mở app iOS đã nghiệm thu.

Đã đọc Dashboard ngày 21/10/2026: đăng ký mới và **Confirm email** đang bật; Site URL đã là `mathlingo://auth-callback`, chưa có redirect URL bổ sung. Không đổi các thiết lập này hoặc tắt xác minh. Sau khi lưu SMTP, Cloud cho phép sửa mẫu và mẫu OTP đã được lưu thành công.

## Kiểm tra sau khi lưu cấu hình

1. Dùng địa chỉ email kiểm thử do người dùng kiểm soát để đăng ký qua ứng dụng; kiểm tra lỗi gửi thư/rate limit nếu có. Không báo thành công nếu Supabase trả lỗi.
2. Xác nhận email đến hộp thư hoặc Spam, đúng From/subject; mã được sinh thật và không có placeholder chưa render.
3. Nhập mã trong ứng dụng; chỉ chuyển sang đăng nhập khi server xác nhận. Mã sai, hết hạn hoặc dùng lại phải bị từ chối.
4. Kiểm tra gửi lại sau cooldown và liên kết xác minh trên Android. Xác nhận đúng user đã có `email_confirmed_at`, không tự cập nhật cột này bằng SQL.
5. SMTP dùng chung cho email Auth; kiểm tra quên mật khẩu sau thay đổi mà không sửa mật khẩu người dùng hiện có.

Không chạy signup/resend hàng loạt. Giữ rate limit đang có khi chưa đo nhu cầu thực tế. Gmail có giới hạn gửi thư; cấu hình cho demo/phát triển không đồng nghĩa đã nghiệm thu gửi email quy mô production.

## Cấu hình local

[config.toml](D:/DEMO/PRM391/supabase/config.toml) bật xác nhận email và tham chiếu template local. Chỉnh file này không tự đổi SMTP hoặc template trên Cloud. Local có thể dùng mail catcher của Supabase; cấu hình SMTP thật trên Cloud theo các bước trên.

Nguồn: [Supabase Custom SMTP](https://supabase.com/docs/guides/auth/auth-smtp), [Supabase email templates](https://supabase.com/docs/guides/local-development/customizing-email-templates), [Google SMTP settings](https://support.google.com/mail/answer/7104828?hl=en), [Google app passwords](https://support.google.com/mail/answer/185833).

## Kiểm tra workspace ngày 21/10/2026

- TOML parse đạt; config bật xác nhận email và tham chiếu đúng template OTP đã có. Template và mã Flutter hiện tại được giữ nguyên.
- `flutter analyze --no-pub`: không có lỗi/cảnh báo.
- `flutter test --no-pub test/email_verification_test.dart test/auth_layout_test.dart`: 6 test đạt, gồm mã/liên kết, link sai server, token hết hạn/rate limit và màn xác minh chữ lớn.
- `git diff --check`: đạt.
- Log: `D:/DEMO/PRM391/build/smtp-analyze.log`, `D:/DEMO/PRM391/build/smtp-auth-tests.log`.
- Đã lưu SMTP và mẫu Confirm sign up sau xác nhận trực tiếp của người dùng. Lần lưu SMTP đầu chưa tồn tại sau reload nên đã điền lại đầy đủ và lưu thành công; không lấy việc click nút làm bằng chứng hoàn thành. Mẫu OTP cuối đã tải lại từ máy chủ, subject/nội dung đúng và không còn mẫu tiếng Anh mặc định.
- Đăng ký thử qua Auth API thật: HTTP 200, tạo user chưa xác minh, không cấp session đăng nhập. Database xác nhận `confirmation_sent_at` có giá trị, `email_confirmed_at` vẫn chưa có; không tự xác minh bằng SQL.
- Email thử: `Khazim2810+mathlingo-smtp-20261021-68f854@gmail.com`, được gửi về cùng hộp thư Gmail của người dùng. Người dùng trả lời **“đã nhận được”**. Kết nối gửi/nhận đã được xác nhận, không chỉ dựa vào HTTP 200.
- Tài khoản thử `be8e23e7-233b-443e-81ee-c9a9ada89a47` vẫn chưa xác minh; không có parent profile tại lần đọc kiểm tra. Không tự xóa hoặc sửa tài khoản hiện có. Mật khẩu ngẫu nhiên thử không được ghi ra log/tài liệu. Metadata kết quả không chứa credential nằm tại `D:/DEMO/PRM391/build/smtp-signup-result.json` (ignored).
- Chưa nhập OTP thật để hoàn tất đăng ký/đăng nhập trên thiết bị, chưa chạy gửi lại, quên mật khẩu hoặc iOS E2E trong lượt này. Các bước đó không được tính là đã nghiệm thu chỉ từ việc nhận thư.
