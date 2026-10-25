# Phân tích Brilliant bằng REA

**Cập nhật 23/10/2026:** đã đối chiếu và áp dụng font, CSS palette và các thành phần
giao diện nguồn. Xem [STYLE_RECONSTRUCTION.md](STYLE_RECONSTRUCTION.md) cùng
evidence mới. Phần MVP bên dưới là bản ghi lịch sử trước khi chuyển 12 thử thách
sang tương tác và trước đợt cập nhật font/màu; không còn mô tả đầy đủ bản hiện tại.

Ngày 22/10/2026. Nguồn: https://brilliant.org/. Phạm vi: website công khai ở viewport mobile, không phải APK/IPA hoặc tài khoản đã đăng nhập.

## Phương pháp

REA `capture_browser_scenario`, Chrome 155, hồ sơ tạm, viewport 390 × 844. Thu accessibility, URL và screenshot; REA chủ động thực hiện các click khai báo. Chuyển sang REA CLI 6.7.0 khi MCP chờ lâu; từng thao tác CLI có timeout. Kết quả đầy đủ được lưu trong `evidence/*-cli.json`. `landing.json` là bản trích gồm digest DOM, accessibility và giới hạn. Các tác vụ không trả kết quả không dùng làm bằng chứng.

Tuổi 25, trình độ và sở thích là dữ liệu giả lập. Không tạo tài khoản hoặc thanh toán. Không mở binary target nên không có phiên native cần đóng. Các trình duyệt CLI thành công báo cleanup `terminated-owned-process`.

## Quan sát trực tiếp

| Phát hiện | Tệp / Evidence ID |
| --- | --- |
| Trang công khai giới thiệu học trực quan, hỗ trợ, thực hành và tiến độ | `landing.json` / ev_f1d686f6ef41f0f8e38d165dfd4a7a7ca3740e505bf612adb718ee5d13eaaaed |
| Learner → `/welcome/?cta_persona=learner`, chào Koji | `learner-entry.json` / ev_78f87092d57930ddae08b9331de660ab9c04b0c6043845d347bce43694668cd7 |
| Chọn động lực bằng radio, Continue khóa trước khi chọn | `onboarding-cli.json` / ev_56f693eb40d823e1d45111e4a063c9040e2a297799cdeb15e65c498673566371 |
| Chọn giọng Melodic/Deep, công tắc Voice on | `motivation-cli.json` / ev_0f75cd8dde02d29e08524778dbf7f688d81e9873e9728277a03447b83d3d4a31 |
| Giới thiệu hỗ trợ có biểu thức toán, khối đáp án minh họa, tiến độ chia đoạn và Continue dưới cùng | `voice-cli.json` / ev_720a53333df899892e9ac1b58a896533e663c4a2dbc57ab1b8d3f4c15f08c46c; `brilliant-onboarding.png` |
| Tuổi → môn Math/CS → giới thiệu đội ngũ → trình độ toán | `help-cli.json`, `age-cli.json`, `subject-cli.json`, `experts-cli.json` (ID giữ trong từng JSON) |
| Basic Algebra dẫn đến ba câu tự đánh giá | `level-cli.json` / ev_44ad93013f64f0ea6c9ca53ebafd97bffd94018db804e8cb1a06b1bf7dbb7d19 |
| Câu hỏi hình tọa độ và No/Maybe/Yes; chọn Yes chuyển câu tiếp | `diagnostic-cli.json` / ev_e7b0ee4fbd0a2ba6b193d38e37da00a5417f7439b9aff76d6f804063f9d68ded; `confidence-cli.json` |
| Ba câu về khoảng cách hai điểm, khoảng cách đường thẳng và phương trình đường tròn; sau câu ba chuyển màn | `confidence-end-cli.json` / ev_e1816b606ee0fca877a96a93795ec2743089f3dbf779239bcacddc0bd436f446 |
| Chọn mục tiêu 10/20/30/60 phút/ngày | `plan-cli.json` / ev_9e1d0131989a5892d6d7f0aa78bf6a8f58485b74b58a11650bf417b056e0b94f |
| Sau chọn 10 phút có chọn thời điểm học | `daily-cli.json` / ev_1ae3152f0633c83fed0d8eca0f7ab9403d23010d65863db9f135731c5e5215f5 |

Luồng quan sát: trang công khai → learner → chào → mục tiêu → giọng → hỗ trợ trực quan → tuổi → môn → giới thiệu → trình độ → ba câu tự đánh giá → giới thiệu → mục tiêu hằng ngày → thời điểm học. Đây là onboarding/chẩn đoán, chưa chứng minh cơ chế chấm bài thật.

Lần thử chọn Another time sau đó không trả kết quả và đã dừng; không suy luận màn hình tiếp theo. Kịch bản tái chạy `scenario.json` chứa cả bước thử này; Evidence hợp lệ gần nhất là `daily-cli.json`.

## Giao diện và tương tác

Ảnh chẩn đoán cho thấy nền trắng, một câu hỏi chính, hình lớn ở giữa, lựa chọn rộng phía dưới. Thanh tiến độ, quay lại và âm thanh ở phía trên. Radio điều khiển trạng thái Continue hoặc tự chuyển câu. Ảnh onboarding có khối đáp án toán nhưng chưa kiểm tra kéo thả trên chúng. Nội dung marketing có biến thể giữa các lần tải; chưa xác minh cơ chế phân phối.

## Chuyển sang Flutter: thiết kế độc lập

| Nguyên tắc | MVP Nảy | Mức xác nhận |
| --- | --- | --- |
| Một nhiệm vụ/màn, hình lớn | Cân, phân số, chuyển động, cột dữ liệu | Thiết kế mới dựa trên quan sát |
| Tiến độ và nút cuối màn | 1/3, thanh tiến độ, kiểm tra/tiếp tục | Điều chỉnh cho app |
| Hỗ trợ khi mắc kẹt | Gợi ý tĩnh, sửa đáp án, giải thích | Nội dung mới, không phải AI Koji |
| Học qua thao tác | Slider cập nhật hình và nhập số | Cơ chế mới, chưa xác minh giống Brilliant |
| Theo dõi học | Resume theo khóa, XP và hoàn thành cục bộ | Quyết định sản phẩm, không suy từ API nguồn |
| Nhận diện | Nền kem, xanh lá, hình vẽ Flutter, tên Nảy | Nhận diện riêng, không dùng tài sản Brilliant |

State flow: chưa trả lời → có đáp án → kiểm tra → sai (sửa/thử lại) hoặc đúng (giải thích/tiếp tục) → hoàn thành → lưu tiến độ. Thoát có xác nhận; mở lại khôi phục câu/đáp án. Mỗi khóa có một bài ba thử thách; không có bài khóa giả.

## Chưa xác minh / giới hạn

- Luồng học sau tài khoản, kho trả phí, cách chấm điểm, lịch ôn và thuật toán thích ứng thật.
- API/backend, AI/voice, đồng bộ phiên hoặc dữ liệu người dùng Brilliant.
- Cử chỉ kéo thả trên bài thật; hình onboarding chỉ chứng minh cách trình bày.
- App native Android/iOS của Brilliant.

Đây là **MVP Flutter lấy cảm hứng từ phần công khai**, không phải bản chuyển mã nguồn hay bản sao đầy đủ. Nội dung marketing không được xem là bằng chứng thuật toán chạy thật. Accessibility không đảm bảo bao phủ canvas; thứ tự event không chứng minh quan hệ nhân quả mạng. Giữ nguyên các giới hạn REA trong JSON.

## Kiểm tra Flutter

Analyzer sạch; 8 ca test đạt (sai/thử lại, bốn khóa, lưu/khôi phục, XP không trùng, màn hình 320px). Android debug APK và web build thành công. Đã xem ảnh home/lộ trình/bài học ở Chrome 390 × 844, không ghi nhận lỗi JavaScript trong lượt kiểm tra. Chưa chạy APK trên thiết bị thật hoặc build iOS.
