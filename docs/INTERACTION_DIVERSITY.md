# Đa dạng tương tác theo chủ đề

Yêu cầu sản phẩm: mỗi chủ đề cần nhiều dạng thao tác phục vụ khái niệm đang học; không chỉ thay số trong cùng một mô hình. Giao diện dùng chung hệ REA đã ghi trong STYLE_RECONSTRUCTION.md và UNIFIED_LAYOUT.md. Đây là thiết kế tương tác của Matlingo, không phải kết luận về bài học sau đăng nhập của Brilliant.

Đợt này bổ sung vào cuối luồng chủ đề:

| Chủ đề | Hoạt động mới | Mục tiêu |
|---|---|---|
| Phân số | Kéo điểm trên trục số chia 8 nấc; có nút tiến/lùi | Chuyển từ phần của hình sang vị trí 3/4 |
| Logic | Bật/tắt hai đèn để dựng phản ví dụ | Phân biệt điều kiện và kết luận của mệnh đề |
| Dữ liệu | Kéo một điểm ngoại lệ, quan sát trung bình và trung vị | Khám phá độ nhạy khác nhau của hai đại lượng |

Các hoạt động dùng ID mới, trạng thái JSON riêng và validator từ mô hình; chạy qua lưu/tiếp tục/hoàn thành hiện có. Không thay hình dạng dữ liệu cũ. Khi chủ đề có bài mới, cơ chế tiếp tục hiện có chọn hoạt động chưa hoàn thành; XP chủ đề không thưởng lại.

Khung trắng viền xám, màu xanh và font kế thừa theme chung. Điều khiển dùng Slider/Switch có semantics; nút thay thế kéo, Wrap để thích ứng chiều rộng. Chưa có render QA nên chưa khẳng định hoàn toàn khớp giao diện ở 320px hoặc chữ lớn.

Kiểm chứng: `dart tools/check_diverse.dart` đạt 50 kiểm tra miền giá trị, bảng chân trị, kiểu sai và JSON round-trip. Bộ test luồng hiện có đã bổ sung lời giải mới và điều chỉnh tổng bước logic. Flutter test chưa chạy được do quyền ghi SDK và dependency cache của môi trường; round-trip không thay thế kiểm thử lưu tích hợp.

Hướng tiếp theo: mô phỏng xác suất qua nhiều lượt; vẽ/đọc đồ thị chuyển động; gập lưới hình học; chạy từng lệnh và kiểm thử chương trình trên nhiều đầu vào. Cần triển khai và kiểm chứng riêng, chưa có trong đợt này.
