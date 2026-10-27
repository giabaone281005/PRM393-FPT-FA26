# Email xác nhận Matlingo

`confirmation.html` là body cho **Authentication → Emails → Templates → Confirm signup**
trong project `seoswmcldwwytdrfrrrb`. Subject: **Mã xác nhận tài khoản Matlingo**.
Nếu Dashboard dùng navigation cũ, tìm **Authentication → Email Templates → Confirm signup**.

Template dùng `{{ .Token }}` thật do Supabase render, không có mã cố định hoặc link
tự tiêu thụ token. Giữ bật Confirm email và giữ nguyên thông tin SMTP hiện có.
Mẫu này thay giao diện email; nó không tự cấu hình SMTP hay bảo đảm khả năng gửi thư.

Mobile nhập OTP qua `verifyOTP(email: ..., token: ..., type: OtpType.email)`;
gửi lại qua `resend(type: OtpType.signup, email: ...)`. App nhận mã 6–10 chữ số,
có hỗ trợ dán/autofill, cooldown gửi lại 60 giây. Expiry/rate limits do server quyết định.
Những mã đã phát trước khi thay template vẫn do server xác thực bình thường.

REA tokens: nền trắng, mặt phụ `#F8F8F8`, chữ đen, chữ phụ `#666666`, viền
`#E5E5E5`, xanh `#29CC57`, nền thành công `#EAFAEE`, radius 16/24px. Email dùng
inline CSS và presentation tables. Font app có fallback Georgia/Arial/Courier
vì email client không bảo đảm hỗ trợ custom font; không tuyên bố giống tuyệt đối.

## Áp dụng

1. Mở [Confirm signup](https://supabase.com/dashboard/project/seoswmcldwwytdrfrrrb/auth/templates).
2. Đặt subject như trên; dán toàn bộ `confirmation.html` vào body và Save.
3. Xem Preview; đăng ký một email mới hoặc bấm **Gửi lại mã** trong app.
4. Nhập mã nhận trong email vào ô **Mã xác nhận**, chọn **Xác nhận & tiếp tục**.

Đã áp dụng và đọc lại để xác minh trên hosted project ngày 26/10/2026 bằng
Management API của phiên CLI đã được người dùng đăng nhập: subject, toàn bộ HTML
và sender name Matlingo. SMTP credentials, Confirm email và độ dài OTP 8 chữ số
được giữ nguyên. Chưa xác nhận thư thực nhận trong hộp thư của người dùng.
Không đưa Management token/SMTP password vào source hoặc gửi trong chat.

Tài liệu chính thức:
[email templates](https://supabase.com/docs/guides/auth/auth-email-templates),
[verify OTP](https://supabase.com/docs/reference/dart/auth-verifyotp),
[resend](https://supabase.com/docs/reference/dart/auth-resend).
