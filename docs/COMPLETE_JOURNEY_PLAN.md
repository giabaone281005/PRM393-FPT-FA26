# Luồng học hoàn chỉnh và phòng thí nghiệm tương tác

## Phạm vi triển khai

1. Vào app → đăng nhập/hồ sơ → chọn sở thích và nhịp học → trang hôm nay.
2. Chọn trong 8 chủ đề, mỗi chủ đề có một hành trình gồm 3 thử thách khác nhau.
3. Mỗi thử thách có trạng thái mô hình, kiểm tra từ mô hình, thử lại, gợi ý và reset.
4. Tự lưu sau thao tác và khi app chuyển nền; mở lại tiếp tục đúng bài, đúng bước.
5. Hoàn thành → tóm tắt thao tác/XP → gợi ý chủ đề kế tiếp → lịch sử học.
6. Đăng xuất và đổi hồ sơ không làm lẫn tiến độ; không cộng XP lại khi ôn.

## Nguyên tắc nội dung

- Không có trang lý thuyết phải đọc trước, câu hỏi trắc nghiệm hay chọn đáp án.
- Tìm hiểu bằng xây dựng, kéo thả, xoay, vẽ, nối, chạy và quan sát.
- 24 cơ chế có định danh riêng; mỗi chuỗi ba bước đổi cách thao tác.
- Một động tác có hệ quả nhìn thấy ngay, gợi ý ngắn theo thí nghiệm đang làm.
- Hệ thiết kế giữ font, palette, CTA và typography REA; cơ chế mới là thiết kế của app.
- Chỉ thêm thư viện/engine khi có nhu cầu cụ thể; Flutter canvas/gesture/ticker
  đáp ứng các mô hình 2D hiện tại và giữ đường build mobile đơn giản.

## Trạng thái triển khai

- [x] Session, hồ sơ và lưu trữ phiên bản mới.
- [x] Entry/onboarding, thư viện chủ đề, resume và lịch sử.
- [x] 12 cơ chế toán/logic/khoa học/dữ liệu.
- [x] 12 cơ chế hình học/lập trình/mạch điện/xác suất.
- [x] Kiểm thử session, resume, sửa sai, hoàn thành, isolation và các cơ chế mới.
- [x] REA xem trước, phân tích mã, build APK và web.

Người dùng đã chọn hồ sơ trên thiết bị, dùng offline. Màn vào app tạo/mở lại
hồ sơ cục bộ; không yêu cầu email hay mật khẩu, không có backend/đồng bộ cloud.
