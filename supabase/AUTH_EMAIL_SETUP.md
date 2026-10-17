# Xác minh email và khôi phục mật khẩu

App dùng mã email qua Supabase verifyOTP. Không cần mở custom-scheme link trên máy tính hoặc chuyển session giữa máy tính và emulator.

## Cấu hình Cloud cần thực hiện trong Supabase Dashboard

Connector hiện tại không có công cụ cập nhật Auth email templates hoặc SMTP. Các file trong repo không tự thay đổi cấu hình Cloud.

1. Authentication → Email → Templates: Confirm signup dùng nội dung `templates/confirmation.html`; Reset password dùng `templates/recovery.html`. Cả hai dùng `{{ .Token }}` và không đặt link chuyển về `mathlingo://`.
2. Authentication → Email → SMTP Settings: cấu hình SMTP của dịch vụ email bạn sở hữu (sender, host, port, username, password). Không thêm mật khẩu SMTP hoặc service key vào config Flutter/repo.
3. Giữ yêu cầu xác minh email. Không tắt xác minh, không đặt token vào SQL, không dùng service key để bỏ qua recovery.

Trước khi đổi template, app vẫn hỗ trợ dán link gốc từ email hiện tại vào màn hình xác minh tương ứng. Chỉ nhận link HTTPS của đúng Supabase project, đúng `/auth/v1/verify`, đúng signup/email hoặc recovery. App không truy cập redirect URL và không nhận access-token fragment từ một trình duyệt khác. Link đã bấm/đã dùng cần email mới.

## Kiểm thử sau cấu hình

- Đăng ký email mới → nhận mã → nhập trong app → quay lại đăng nhập; mã sai/hết hạn bị từ chối.
- Quên mật khẩu → nhận mã recovery → nhập → chọn mật khẩu mới → đăng xuất → mật khẩu cũ bị từ chối, mật khẩu mới đăng nhập được.
- Đọc Gmail trên máy tính, nhập mã trong emulator: không mở trang trống và không phụ thuộc deep link.
- Thử gửi lại: app có thời gian chờ 60 giây, báo lỗi 429 rõ ràng và vẫn cho dùng mã/link đã nhận. Thời gian chờ trong app không thay thế quota của Supabase.
- Không khẳng định kiểm thử email Cloud đã đạt nếu chưa thực sự nhận và nhập mã. Việc có file template không xác nhận SMTP đã được cấu hình.

Tài liệu: https://supabase.com/docs/guides/auth/auth-email-templates và https://supabase.com/docs/guides/auth/auth-smtp
