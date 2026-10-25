# Trang chủ, Chủ đề, Hồ sơ — 24/10/2026

## Thiết kế và REA

Theo bốn ảnh người dùng cung cấp: loại bỏ card gợi ý và card lộ trình trên home, rút gọn CTA, gom topic thành nhóm với icon, tiến độ và dấu hoàn thành. Ba tab chính là Trang chủ, Chủ đề, Hồ sơ; loại bỏ trang Hành trình cũ.

REA chạy Chrome headless tại https://brilliant.org/courses/, chờ 1,5 giây và thu DOM/accessibility. Kết quả quan sát có các cấp heading Topics → Math/Programming & CS → Math Foundations/Algebra Fundamentals và mô tả từng nhóm. Đây là bằng chứng cho cách nhóm nội dung công khai; ảnh người dùng là tham chiếu cho trạng thái tài khoản, tiến độ và thành tựu. Không truy cập tài khoản Brilliant.

Evidence: `ev_2a4d13d635bc71de28c65d9eb28946c8b1ede9e3b67a492399c984bafe8f7d5f`; [tóm tắt](evidence/topics-layout-rea.json). DOM/accessibility đầy đủ trong phạm vi capture đã chọn, không thu network event cho lượt khảo sát này.

## Kết quả

- Trang chủ: không có bản nháp thì nút Chọn chủ đề mở tab Chủ đề. Có bản nháp thì hiển thị chủ đề gần nhất, bước đang làm, tiến độ và nút Học tiếp mở lesson đã lưu. Đổi chủ đề vẫn giữ bản nháp.
- Chủ đề: 8 topic trong 3 nhóm, thẻ icon cuộn ngang, tiến độ 3 thí nghiệm, trạng thái hoàn thành, bộ lọc và tìm kiếm. Thành tựu, XP và lịch sử nằm trong phần mở rộng ở cuối trang này.
- Hồ sơ: tab trực tiếp cho hồ sơ đang dùng, nhịp học, lưu phiên và đổi hồ sơ.
- Cài đặt ở header: nền Trắng/Kem/Xám dịu; màu nhấn Xanh lá/Xanh lam/Tím; ba cỡ chữ; hai kiểu tiêu đề; giảm chuyển động. Thay đổi áp dụng vào theme và MediaQuery toàn app. Đây là ba biến thể nền sáng, chưa có chế độ tối.
- Cài đặt lưu riêng ở `matlingo:appearance:v1`, áp dụng cho app trên thiết bị. Hàng đợi ghi tránh mất thay đổi khi bấm liên tiếp; lỗi ghi được báo trong màn cài đặt. Không sửa schema học tập hoặc công thức XP.

## Kiểm chứng

59 kiểm thử đạt: điều hướng 3 tab, chọn bài khi chưa học, resume đúng bước, hồ sơ, cài đặt áp dụng trực tiếp và đọc lại, thay đổi nhanh liên tiếp, dữ liệu cài đặt hỏng, cùng các luồng hoàn thành/lưu sẵn có. Kiểm tra ở chiều rộng 320px và cỡ chữ 130%. Đã xem ảnh render của home trống, home resume, danh sách nhóm và cài đặt.

Bản debug đã build/cài và hiển thị được trên Pixel 9 Android 15. Máy ảo ban đầu chỉ hiện hình nền trong khi cây widget đầy đủ; chuyển renderer không giải quyết được. Khởi động lại máy ảo bằng `-no-snapshot-load` đã khôi phục hiển thị; chạy lại bằng renderer mặc định. Không xóa dữ liệu app hoặc thay cấu hình renderer trong dự án.

Ảnh: [home mới](home-minimal.png), [học tiếp](home-resume-minimal.png), [chủ đề](topics-grouped.png), [cài đặt](appearance-settings.png).
