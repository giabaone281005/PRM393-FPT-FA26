# Nội dung tương tác mở rộng

10 chủ đề, 46 thử nghiệm, tái sử dụng 24 cơ chế tương tác. Không có câu hỏi chọn đáp án.

Tám chủ đề ban đầu giữ nguyên ba bài nền tảng và có thêm hai bài vận dụng/thử thách. Hai chủ đề mới gồm Đại số bằng mô hình và Thuật toán hiệu quả, mỗi chủ đề ba bài.

| Chủ đề | Bài bổ sung / trọng tâm |
| --- | --- |
| Logic | Giữ đẳng thức khi bỏ khối; hiệu chuẩn hộp bí mật bằng phản hồi của cân |
| Phân số | Phân số tương đương 3/4 = 6/8; dựng phần bù |
| Chuyển động | Ghép lịch trình theo quãng đường và điều kiện đầu/cuối |
| Dữ liệu | San đều khi có ngoại lệ; cùng trung bình nhưng khác phân bố |
| Hình học | Dựng hình đáp ứng đồng thời diện tích và chu vi |
| Lập trình | Đường đi tối đa sáu lệnh; đi qua trạm bắt buộc |
| Ánh sáng | Pha lục lam và trắng bằng ba nguồn RGB |
| Xác suất | Túi công bằng; cơ hội xanh gấp ba đỏ, đủ tám viên |
| Đại số | Cô lập ẩn số và biểu diễn quan hệ gấp đôi/gấp ba bằng mô hình |
| Tối ưu thuật toán | Sửa đường sai; hoàn thiện mạng sắp xếp kiểm chứng 24 hoán vị; giới hạn chuyển động |

Mục tiêu và tham số hiển thị thuộc ExperimentSpec.config, tách khỏi trạng thái người học. Cân, phương trình, túi bi và mẫu màu dùng tham số của bài. Mỗi bài có mục tiêu, gợi ý, giải thích và bộ kiểm tra trạng thái thực tế. Nhiều mô hình hợp lệ được chấp nhận khi đề bài cho phép.

Tiến độ, bước cuối, thanh tiến độ, số bài và màn hoàn tất đều dùng độ dài danh mục. Hồ sơ đã có bản ghi hoàn thành được ghi nhận các experimentIds cũ; khi có bài mới, mở từ bài bổ sung đầu tiên. Việc hoàn tất vẫn kiểm tra các bài mới, giữ XP cũ và không thưởng trùng. Hồ sơ cũ không lưu experimentIds vẫn giữ thành tích và có thể học lại.

Kiểm chứng: 75 tests qua; 46 màn bài học chạy ở 320 px, kiểm tra luồng hoàn thành của cả 10 chủ đề, khôi phục JSON, điều kiện phụ, thao tác phương trình hơn ba lần và chuyển tiếp bản ghi hoàn thành cũ. Flutter analyze không có lỗi. Bản debug đã cài lên Pixel 9 emulator.

Ảnh kiểm tra: extended-geometry.png, extended-optimization.png.
