# Icon trang chủ — 24/10/2026

## Tham chiếu và REA

Ảnh người dùng cung cấp là tham chiếu cho giao diện home đã đăng nhập: vật thể nổi, mặt khối khác màu, bóng mềm, đồng xu vàng và xúc xắc xanh. Bộ icon mới được vẽ riêng bằng Flutter Canvas, không phải asset trích xuất của Brilliant.

REA thực hiện một scenario khai báo trên https://brilliant.org/ với Chrome headless, chờ 2 giây và thu DOM/network metadata. DOM thu được có 22 SVG và 3 `button3d-face`, đồng thời tham chiếu cả ảnh SVG và PNG. Trang công khai không xác minh cách triển khai icon trong home đã đăng nhập của ảnh mẫu. Một số request chưa hoàn thành khi capture kết thúc; không suy diễn network đầy đủ hoặc định dạng asset riêng tư.

Evidence: `ev_651ac663e0d3eab014560d9577aba951e7a70f9a766edaa7bb6fc0178afe23e5`. Tóm tắt: [home-icons-rea.json](evidence/home-icons-rea.json).

## Đã triển khai

- 8 minh họa vector có chiều sâu: bánh răng, phân số, tên lửa, biểu đồ, hình khối, robot, bóng đèn, xúc xắc–đồng xu.
- Dùng chung trên home, thẻ tiếp tục, danh sách chủ đề và header chủ đề. Dải shortcut ngang trên home mở trực tiếp từng chủ đề.
- Card gợi ý dùng nền gradient dịu, viền và bóng mềm; minh họa lớn 180px. Màu xanh/tím/vàng nằm trong artwork, giữ typography và các thao tác chung của app.
- Canvas chỉ vẽ hình trang trí, có nhãn accessibility và RepaintBoundary. Không tải mạng, asset raster hoặc engine 3D; không có animation lặp vô hạn.

## Kiểm chứng

- 54/54 kiểm thử đạt, bao gồm mở chủ đề từ shortcut ở 320px và các luồng lưu/hoàn thành có sẵn.
- Phát hiện và sửa tràn nhãn shortcut 5px ở font kiểm thử; chiều cao dải icon thích ứng theo cỡ chữ.
- Đã render và xem trực quan cả trang chủ và 8 icon. Ảnh xem trước dùng hồ sơ giả Bảo và chủ đề xác suất; không sửa dữ liệu hồ sơ đang dùng trên emulator.
- Ảnh: [trang chủ](home-dimensional-icons.png), [bộ icon](topic-icon-sheet.png).

Render lại: `flutter test test/icon_visual_preview_test.dart`.
