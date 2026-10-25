# Bài học không gian trên mobile

## Nội dung đã triển khai

- **Hình học:** xoay khối hộp, đổi ba cạnh, thỏa đồng thời thể tích 12 và diện tích bề mặt 32; chấp nhận hoán vị cạnh hợp lệ.
- **Đại số:** dựng khối thỏa thể tích và hai quan hệ giữa các kích thước.
- **Địa lý:** chủ đề mới trong danh mục và lộ trình thế giới vật lý. Xoay quả địa cầu, chạm chọn vị trí trên bán cầu đang nhìn thấy, điều chỉnh kinh/vĩ độ, đưa điểm chọn về phía trước. Lưới tọa độ cách nhau 15°, chưa có texture lục địa, địa hình, biên giới hoặc dữ liệu bản đồ thực.
- **Địa chất:** khối ba lớp có tuổi giả định, xoay để xem mặt cắt và đổi thứ tự lớp. Điều kiện bài chỉ áp dụng cho chuỗi trầm tích chưa bị đảo lộn; không suy tuổi từ màu hoặc loại đá.

## Engine và giao diện

`lib/experiments/solid_model.dart` là engine hình học nhỏ viết bằng Dart: tọa độ 3D, quay hai trục, chiếu phối cảnh cho khối, sắp mặt theo độ sâu; quả cầu dùng phép chiếu trực giao và phép chọn điểm ngược. Flutter Canvas tô các mặt và lưới. Đây là renderer nội bộ cho mô hình đơn giản, không phải Unity, engine vật lý, bộ nạp glTF hay bản đồ GIS.

Giao diện kế thừa theme, font và khung bài theo bằng chứng REA hiện có; không có khảo sát Brilliant mới trong đợt này. Màu đất chỉ phân biệt lớp trong mô hình. Vùng nhìn tự co theo chiều rộng, tối đa 300px; nút thay thế kéo, điều khiển có nhãn trợ năng và không có vòng animation tự chạy. Camera chỉ là trạng thái xem, không tạo tiến độ hoặc ghi storage mỗi frame.

Hoạt động dùng ID mới và luồng lưu/tiếp tục, kiểm tra, XP hiện có. Kích thước, tọa độ và thứ tự lớp lưu trong JSON; góc camera đặt lại khi mở bài. Không đổi schema hồ sơ hoặc thưởng lại XP của chủ đề đã hoàn thành.

## Kiểm chứng và giới hạn

- `dart tools/check_space.dart`: đạt 17.552 kiểm tra, gồm vét cạn 125 bộ kích thước, điều kiện đại số, thứ tự lớp, miền tọa độ, khôi phục JSON, độ sâu mặt và phép chọn điểm qua nhiều góc nhìn. Kiểm tra tương tác trước đó (`check_diverse.dart`) vẫn đạt 50 trường hợp.
- Phân tích tĩnh các file engine, catalog, workspace, danh mục và minh họa không có lỗi.
- Phân tích riêng phần tích hợp `journey_app.dart`/`discovery_paths.dart` còn lỗi `String.characters` đã xuất hiện trước đợt này trong môi trường thiếu dependency cache; chưa xác nhận toàn dự án sạch.
- Thêm widget test cho điều khiển, khóa thao tác, xoay không đổi đáp án, màn 320px/chữ lớn/giảm chuyển động; cập nhật fixture và tổng danh mục: 11 chủ đề, 53 hoạt động, 30 cơ chế.
- Widget test, render QA, build APK và đo FPS chưa xác nhận trong đợt này: môi trường hiện tại không ghi được lockfile Flutter SDK và không đọc đủ dependency cache. Không coi kiểm tra toán học là bằng chứng hiệu năng hoặc giao diện native.

Đợt tiếp có thể bổ sung bản đồ bề mặt/texture có nguồn dữ liệu rõ ràng, địa hình và mặt cắt tương tác. Cần benchmark thiết bị trước khi chọn renderer GPU tổng quát hoặc tăng độ phức tạp mô hình.
