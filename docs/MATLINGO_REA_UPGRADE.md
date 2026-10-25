# Matlingo — khảo sát REA và nâng cấp tính năng

Ngày: 23/10/2026. Bản ứng dụng: 1.3.0+4.

## Phương pháp và phạm vi

Đã dùng skill REA tại `C:/Users/kzrok/.agents/skills/reverse-engineer-anything/SKILL.md`. REA chạy các scenario có khai báo trên Chrome headless, hồ sơ tạm, viewport 390×844. Thu DOM/accessibility của trang chủ, hai trang trợ giúp chính thức và thực hiện learner entry công khai. Không đăng nhập, tạo tài khoản Brilliant, mua gói hoặc truy cập bài trả phí.

Khảo sát mới tái sử dụng báo cáo/style evidence cũ làm nền. Không đánh đồng tài liệu marketing với kiểm chứng thuật toán thích ứng hoặc AI đã chạy. “Thu hút” ở đây là lựa chọn thiết kế theo ba tiêu chí: khuyến khích khám phá bằng thao tác, giúp người học biết bước tiếp theo, và phù hợp offline. Chưa có khảo sát người dùng để xếp hạng mức yêu thích thực tế.

## Bằng chứng mới

| Evidence ID | Quan sát | Giới hạn |
|---|---|---|
| `ev_a8ebb1ab383ce72987dca1401d06e89642cd566300e2448f834b61de1c453edf` | Trang chủ công khai trình bày canvas tương tác, hỗ trợ khi gặp khó, thực hành có mục tiêu và báo cáo tiến độ | Quan sát nội dung giới thiệu, không chứng minh thuật toán thực thi |
| `ev_9141a68c42ee72507dd701e0e75d12dc756e178e998f5256d1e6d9160e2aefcf` | Help mô tả Learning Paths có thứ tự đề xuất và điểm thực hành kiểm tra | Chưa xem trọn lộ trình sau đăng nhập |
| `ev_cac91add2d4b19e12fadd811fc8b201b6100ea7efbe2265fda1d24bee9448506` | Help mô tả Koji dùng trạng thái tương tác để hướng dẫn người học | Chưa kiểm chứng chat, giọng nói hoặc hành động AI thật |
| `ev_6e3ef9e657ec5eaf229971df95dd124fde0e0133cf5e729f40e67c2b976d5527` | REA bấm learner và quan sát chuyển tới welcome | Capture cuối chỉ có Continue; không suy diễn nội dung canvas không có trong accessibility |
| `ev_5f887ee1ee05f67a2e933a6b9321377a62d4efd9a1bbddacdcda3db23d08c991` | REA thực hiện đủ 14 thao tác khai báo trong Matlingo: tạo hồ sơ thử, onboarding, homepage, Khám phá và lộ trình | Kiểm chứng Flutter web ở 390px; không thay thế kiểm tra native |

Bundle gốc: `evidence/matlingo-feature-rea.json`. Bundle còn chứa các record cũ đã có trong phiên REA; bảng trên xác định riêng những record dùng cho lượt này. Browser do REA mở được đóng sau scenario (`terminated-owned-process`). Không mở native binary target nên không có phiên binary cần đóng.

Nguồn công khai:

- [Brilliant homepage](https://brilliant.org/)
- [Learning Paths](https://brilliant.org/help/features/what-are-learning-paths/)
- [Koji](https://brilliant.org/help/features/how-does-koji-work/)

## Chọn tính năng để nâng cấp

| Ý tưởng tham khảo | Đã áp dụng trong Matlingo | Chưa áp dụng |
|---|---|---|
| Learning Paths | 3 tuyến gợi ý kết nối toàn bộ 8 chủ đề; có tiến độ, trạng thái đang học/đã khám phá và mở chủ đề trực tiếp | Chương trình nhiều cấp, nội dung mới, checkpoint liên chủ đề |
| Lần học tiếp theo có lý do | Trang Hôm nay ưu tiên bản nháp, sau đó bài nên ôn rồi chủ đề mới theo sở thích; hiển thị lý do | Thuật toán cá nhân hóa/AI tương đương Brilliant |
| Thực hành và tiến độ | Khu vực “Những ý tưởng nên gặp lại” trong Hành trình; số phiên đã hoàn thành và mở lại bài | Chấm mức vững kỹ năng, sinh bài mới hoặc spaced repetition thích ứng |
| Trợ giúp bám mô hình | Gợi ý và phản hồi sai đọc trạng thái cho 8 cơ chế: cân, đòn bẩy, tô phân số, robot, nối dây, công tắc, chia vật và ghép tam giác | Chat/voice, vẽ bằng AI hoặc tự thay đổi mô hình |
| Hình ảnh nhất quán | Logo chữ Matlingo tại entry, onboarding, home; đổi tên hiển thị Android/iOS/web và app title | Không thiết kế lại app launcher icon trong lượt này |

Các chức năng bổ sung là thiết kế riêng của Matlingo. Bản đồ chỉ tổ chức 24 thí nghiệm đã có, không tuyên bố thêm khóa học mới. Bài ôn hiện dùng lại bài cũ; chưa tạo biến thể tự động.

## Quy tắc offline đang dùng

- Bản nháp hợp lệ gần nhất được ưu tiên.
- Chủ đề đã hoàn thành được gợi ý ôn nếu phiên gần nhất có từ 6 lần kiểm tra, từ 2 gợi ý hoặc đã qua 7 ngày UTC. Đây là ngưỡng thiết kế ban đầu, không phải đánh giá năng lực.
- Một phiên ôn nhẹ nhàng hơn có thể xóa lý do hỗ trợ của phiên trước; ngày ôn được tính lại từ lần hoàn thành gần nhất.
- Nếu học hết, chọn chủ đề lâu chưa gặp lại. Người học vẫn được mở bất kỳ chủ đề nào.
- Số phiên hiển thị lấy từ lịch sử đang lưu trên thiết bị (giới hạn 100 bản ghi của bản trước), không phải tổng trọn đời.
- Không đổi storage key, package ID, công thức XP hoặc schema dữ liệu. Ôn lại không cộng trùng XP. Không có tài khoản cloud hay lệnh gửi dữ liệu ra ngoài.
- Gợi ý không ghi đè mô hình. Các cơ chế chưa được hỗ trợ hoặc dữ liệu không hợp lệ tiếp tục dùng hint đã có.

## Mã thay đổi chính

- `lib/discovery_paths.dart`: bản đồ, lối vào lộ trình và danh sách thực hành.
- `lib/learning_guidance.dart`: quy tắc gợi ý và thống kê cục bộ.
- `lib/experiments/contextual_guidance.dart`: quan sát mô hình theo từng cơ chế.
- `lib/journey_app.dart`: tích hợp vào Hôm nay, Khám phá, Hành trình và bài học.
- `lib/entry_flow.dart`, Android/iOS/web metadata: tên Matlingo; logo thu gọn vừa header320px.

## Kiểm chứng

- Kiểm thử giữ bản nháp khi mở bài qua lộ trình và giữ nguyên XP khi điều hướng sang ôn tập.
- Kiểm thử quy tắc đề xuất, lịch UTC, cô lập hồ sơ và gợi ý không làm biến đổi dữ liệu.
- Tiếp tục kiểm tra toàn bộ 24 bài ở 320px, 8 đường hoàn thành, thực hiện cử chỉ, thử sai, lưu/khôi phục và giảm chuyển động.
- REA scenario 14 thao tác hoàn thành; không có page-error trong cửa sổ capture.
- Ảnh: `matlingo-onboarding.png`, `matlingo-home.png`, `matlingo-paths.png`.

Không tuyên bố đã đo FPS, chạy iOS hay kiểm thử APK trên điện thoại thật. Những phần này vẫn thuộc kế hoạch mở rộng.

Kết quả cuối: `flutter analyze` không có lỗi/cảnh báo; **53 kiểm thử đạt**. Build web và Android debug APK thành công cho 1.3.0+4. Log kiểm thử: `matlingo-test-output.txt`. Bản xem trước phục vụ tại http://127.0.0.1:8791/.
