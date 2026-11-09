# Bộ chương trình Studio — 2026-11-09

Đã phát hành trên Supabase `seoswmcldwwytdrfrrrb`, release `ebb10589-e28b-47f7-b36b-1fb4d362476a`, yêu cầu mobile 1.3.7+11.

| Chủ đề | Các bài, mỗi bài 6 phần |
| --- | --- |
| Toán học (4) | Chi tiêu thực tế: ngân sách 100 nghìn; Số nguyên và phân số; Hình phẳng: diện tích và chu vi; Khối hộp: từ diện tích đến thể tích |
| Tiếng Anh (3) | Hello! Giới thiệu bản thân; My day: thói quen hằng ngày; Around town: hỏi và chỉ đường |
| Lập trình (3) | Thuật toán: điều khiển robot; Vòng lặp và biến; Điều kiện và sửa lỗi |

Nguồn nội dung và đáp án: `cms/content/three-topic-curriculum.json`. Tổng cộng 60 phần, gồm 10 phần dẫn nhập và 50 phần tương tác. Các câu hỏi có gợi ý và giải thích riêng. Mỗi bài tiếng Anh có đọc, nghe, nói và viết.

Ba engine mới `listeningChoice`, `speechPractice`, `textEntry` đưa kho Studio lên 33 engine. Mobile tái sử dụng `flutter_tts` và `speech_to_text` đã cài; chỉ bật micro theo thao tác người dùng. Khi thiết bị thiếu âm thanh/nhận giọng nói, có bản chữ và nhập câu thay thế. Luyện nói đối chiếu nội dung và thứ tự từ, không chấm chất lượng phát âm. Viết dùng danh sách câu được chấp nhận; bỏ qua hoa/thường và dấu câu. Không chạy mã tải từ máy chủ.

Migration mới `20261118000000_studio_language_engines.sql` giữ kiểm tra server, phiên bản phát hành và quyền Admin. Không sửa các migration cũ. Kho nội dung Admin mặc định ẩn dữ liệu lưu trữ và có công tắc để mở lại.

21 chủ đề cũ và 140 bài cũ đã chuyển sang lưu trữ, không xóa vật lý. Giữ nguyên 141 phiên bản cũ, các release, phiên học và tiến độ. Sau thay danh mục: 8 tài khoản, 20 phiên, 82 lượt thử, 2 hoàn thành, 60 XP, bằng số trước thay đổi. Có thêm đúng 10 phiên bản mới. Backup đầy đủ lưu cục bộ trong thư mục ignored `build/catalog-backups/`.

`tools/prepare_curriculum_replace.py` chỉ tạo SQL, không tự kết nối DB. Mặc định tạo rehearsal rollback gồm kiểm thử học thật từ template `supabase/tests/three_topic_curriculum_smoke.sql`; `--commit` tạo bản commit. Script khóa xuất bản, kiểm tra baseline và đáp án trước lưu trữ, phát hành qua RPC Admin, rồi kiểm tra số lượng và tiến độ. Baseline guard cố ý ngăn chạy lại sau khi đã áp dụng. Không chạy reset/db push do lịch sử migration local và remote khác nhau.

Kiểm chứng: 322 Flutter tests, bao gồm regression HTTP phiên bản catalogue và hiển thị các chủ đề mới; 72 CMS tests; TypeScript/Vite build; Flutter analyze không lỗi; evaluator parity 1577 expanded + 729 legacy; các bộ standalone 50 / 2491 / 17552; APK debug build và kiểm tra chữ ký. Hosted rehearsal xác nhận 10 đáp án đúng, 10 trạng thái thiếu bị từ chối, 3 hoàn thành/90 XP, phiên bản app và từ chối người không phải Admin; dữ liệu thử rollback toàn bộ. Đọc lại release xác nhận 3 chủ đề/10 bài/60 phần. Security advisors chỉ còn các phát hiện sẵn có (8 private RLS deny-all và cảnh báo leaked-password protection).

Runtime phát hiện request danh mục còn gửi phiên bản 1.3.6; đã sửa thành 1.3.7 và thêm test HTTP đối chiếu với `pubspec.yaml` để ngăn lệch phiên bản. APK có cấu hình cloud, là bản debug để thử nội bộ. Chưa kiểm chứng micro vật lý, iOS hoặc ký phát hành store.

Lỗi runtime thứ hai: các ID mới được tải nhưng không thuộc nhóm khám phá hardcode nên không có thẻ hiển thị. `catalogPaths` nay thêm các chủ đề chưa được nhóm theo đúng thứ tự catalogue. Test kiểm tra đủ 3 ID mới và 4/3/3 bài. Cài đè APK trên Pixel 9 thành công, xác nhận trên UI hierarchy cả ba thẻ chủ đề và trang Toán với checkpoint bài Chi tiêu thực tế / Số nguyên và phân số. Giữ nguyên đăng nhập và dữ liệu thiết bị; không làm bài để thay đổi tiến độ của người dùng.
