# Chat, bố cục và menu — 24/10/2026

- Thẻ chủ đề dùng lưới tự xuống hàng theo chiều rộng và cỡ chữ, không còn dãy ngang bị cắt ở mép. Đã kiểm tra thẻ và nút ở 280/320/390/1024px, cỡ chữ 130%.
- Home có box chat với ô nhập nhiều dòng, gợi ý và nút gửi. Khi chưa kết nối, nút gửi bị vô hiệu và không có request mạng. Bản nháp cùng hội thoại chỉ ở bộ nhớ của hồ sơ hiện tại; đổi hồ sơ tạo lại widget.
- Điểm tích hợp: `LearnApp(chatResponder: ...)`, kiểu `ChatResponder` nhận danh sách `ChatMessage` và trả `Future<String>`. Khi nối backend, có sẵn loading, chặn gửi trùng, hiển thị phản hồi và giữ câu hỏi nếu lỗi. Chưa có endpoint, API key hoặc mô hình AI được cấu hình.
- Header mở popup 5 mục: Cài đặt, Tặng Premium, Giới thiệu, Trợ giúp, Đăng xuất. Mỗi mục thông tin mở trang riêng; Cài đặt mở trang tùy chỉnh hiện có. Đóng popup không thay phiên; đăng xuất giữ hồ sơ và tiến độ.
- Giới thiệu mô tả ứng dụng và dữ liệu offline. Trợ giúp có tìm kiếm, các câu hỏi mở rộng và nội dung dành riêng cho Matlingo. Tặng Premium là trang giới thiệu tính năng sắp có, không tạo đơn hàng hoặc thanh toán.
- Các trang và popup dùng theme, font và điều hướng chung; màu nền/màu nhấn đã lưu vẫn áp dụng.

REA khảo sát `https://brilliant.org/help/` bằng scenario khai báo (Chrome headless, chờ 1 giây, thu accessibility). Quan sát các nhóm câu hỏi, mục quản lý tài khoản và link Help/About/Gift ở footer; thứ tự popup dựa trên ảnh người dùng, không suy diễn từ phiên đăng nhập riêng tư. Evidence: `ev_bd9da40afcc50bf3f5babfe0153b44577ffc3a9e80af5813d7a5f971ef612008`, [tóm tắt](evidence/settings-help-rea.json).

65 kiểm thử đạt: hình học bố cục, chat chưa kết nối, callback thành công/lỗi/history, popup, 4 trang đích, tìm trợ giúp, đăng xuất/khôi phục và các kiểm thử học tập sẵn có. Phân tích mã không có vấn đề.

Ảnh: [chat](home-chat.png), [popup](settings-popup.png), [chủ đề](topics-grouped.png).
