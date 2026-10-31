# Matlingo — Test UI/UX và kiểm thử luồng trước demo

Ngày lập: 28/10/2026. Phạm vi: frontend Matlingo hiện tại, README khai báo phiên bản 1.3.2+6. Ghi lại phiên bản APK thực tế trước khi test. Báo cáo MathLingo legacy không xác nhận chất lượng frontend này.

## 1. Cách sử dụng

1. Điền môi trường và chuẩn bị dữ liệu ở mục 2–3.
2. Chạy P0 trước, sau đó P1/P2. Ghi kết quả thực tế và bằng chứng cho từng ca ở mục 7.
3. Tập kịch bản tại `D:\Brilliant Clone\brilliant_mobile\repo-history\docs\HUONG_DAN_DEMO.md` trên đúng APK/thiết bị sẽ trình bày.

Trạng thái: **NOT RUN** chưa chạy; **PASS** đúng kỳ vọng; **FAIL** sai kỳ vọng; **BLOCKED** thiếu điều kiện thực thi; **N/A** ngoài cấu hình demo, phải ghi lý do. Ca thủ công dưới đây mặc định NOT RUN; test tự động đạt không tự chuyển chúng sang PASS.

Ưu tiên: **P0** chặn demo luồng chính; **P1** cần kiểm tra trước demo đầy đủ; **P2** mở rộng. Nếu trình bày cloud, các ca đăng nhập/đồng bộ/sao lưu tương ứng phải được kiểm tra trước.

## 2. Phiếu môi trường

| Thông tin | Điền trước khi test |
|---|---|
| Tester / ngày giờ / múi giờ | ... |
| Commit / có thay đổi chưa commit? | ... |
| Tên APK / versionName / versionCode / SHA-256 | ... |
| Thiết bị / Android / kích thước màn hình | ... |
| Bản chạy | Offline phát triển / Có cloud |
| Mạng | Wi-Fi / 4G / offline |
| Cỡ chữ hệ thống / cỡ chữ trong app | ... |
| Recovery bật và template đã cấu hình? | Có / Không / Chưa xác minh |
| Engine AI/code thử thành công? | Có / Không |
| Thư mục ảnh/video/log trên máy tester | ... |

Không gỡ app hoặc clear data chứa tiến độ cá nhân để reset. Dùng thiết bị/emulator test riêng hoặc tạo hồ sơ demo mới. Ghi số liệu ban đầu trước mỗi ca để so sánh.

## 3. Dữ liệu test cần chuẩn bị

| Mã | Dữ liệu | Mục đích / trạng thái ban đầu |
|---|---|---|
| D01 | `Demo_Moi_2810` | Hồ sơ mới, chưa hoàn thành Logic, XP cá nhân ban đầu 0; chọn Logic và mục tiêu 10 phút |
| D02 | `Demo_DangHoc_2810` | Làm đúng bài cân đầu tiên, sang Bóc từng lớp, về Trang chủ để có Học tiếp |
| D03 | `Demo_HoanThanh_2810` | Hoàn thành đủ Logic qua UI, ghi XP và lịch sử; dùng kiểm tra ôn lại |
| D04 | `Demo_Rieng_2810` | Chưa học; chứng minh tiến độ giữa các hồ sơ độc lập |
| D05 | Tài khoản test do bạn sở hữu, đã xác nhận email | Đăng nhập cloud; giữ mật khẩu trong trình quản lý mật khẩu, không ghi vào Git/tài liệu/video |
| D06 | Email test khác do bạn sở hữu, chưa đăng ký | Đăng ký/OTP; cần truy cập hộp thư thật, không dùng email giả để chờ mã |
| D07 | Tên `  An Demo  `; rỗng; 41 ký tự `A` | Trim tên; bắt buộc nhập; giới hạn 40 ký tự |
| D08 | Từ khóa `Logic`; `zzzz_demo_404` | Tìm có kết quả / không có kết quả |
| D09 | Email sai định dạng `demo@`; mật khẩu cố ý sai của D05 | Validation / lỗi đăng nhập. Chỉ thử sai một lần để tránh rate limit |
| D10 | Chat `Giải thích vì sao x + 3 = 7 thì x = 4`; Python `print(2 + 3)` | AI/code tùy chọn, chỉ kỳ vọng kết quả thật khi engine tương ứng đã hoạt động |

Có thể thêm hậu tố lần chạy vào tên hồ sơ để không trộn kết quả. Bản cloud cần đăng nhập đúng tài khoản trước khi tạo/chọn hồ sơ; bản phát triển không cấu hình cloud cho tạo hồ sơ thiết bị offline. Không cần chèn SQL hoặc sửa số dư để chuẩn bị dữ liệu.

### Đáp án thao tác cho toàn bộ Logic

Thứ tự lấy từ catalog hiện tại. Mỗi bài: thao tác → **Kiểm tra → Khám phá tiếp**; bài cuối chọn **Hoàn thành hành trình**. Làm ba bài đầu chưa đủ hoàn thành chủ đề.

| Bước | Bài | Thao tác / trạng thái đúng |
|---|---|---|
| 1 | Chiếc cân bí mật | Thả đủ 4 khối (`blocks = 4`) |
| 2 | Bóc từng lớp | Bỏ 3 cặp ở hai vế (`pairs = 3`), còn x = 4 |
| 3 | Truyền chuyển động | Bánh nhỏ quay 2 vòng (`turns = 2`) |
| 4 | Giữ nguyên sự cân bằng | Bỏ 5 cặp (`pairs = 5`), từ x + 5 = 9 còn x = 4 |
| 5 | Hiệu chuẩn hộp bí mật | Cân bằng bằng 6 khối (`blocks = 6`) |
| 6 | Một trường hợp đủ để bác bỏ | Bật A, tắt B (`a = true`, `b = false`) |

Đối chiếu: `D:\Brilliant Clone\brilliant_mobile\repo-history\lib\learning_catalog.dart`, các catalog tại `D:\Brilliant Clone\brilliant_mobile\repo-history\lib\experiments\`, fixture tại `D:\Brilliant Clone\brilliant_mobile\repo-history\test\math_experiments_test.dart` và `D:\Brilliant Clone\brilliant_mobile\repo-history\test\extended_solutions.dart`.

## 4. Test UI/UX

| ID / mức | Điều kiện / dữ liệu | Bước thực hiện | Kết quả mong đợi |
|---|---|---|---|
| UI01 / P0 | Điện thoại demo | Mở Auth nếu có cloud, hồ sơ, Trang chủ, Chủ đề, bài học, Hồ sơ | Tiếng Việt rõ, không vỡ font/tràn chữ; cuộn được; nút chính thấy hoặc cuộn tới được |
| UI02 / P0 | Cloud; form Auth (offline thì N/A) | Để trống và bấm Đăng nhập; thử D09; dùng Next/Done trên bàn phím | Lỗi đúng trường; focus trường lỗi đầu; không kẹt bàn phím hoặc che mất nút sau khi cuộn |
| UI03 / P1 | Đã nhập email | Chuyển Đăng nhập ↔ Đăng ký; thử hiện/ẩn mật khẩu | Tiêu đề/nút đúng chế độ; giữ email, xóa mật khẩu/lỗi khi đổi chế độ; hiện/ẩn không đổi giá trị |
| UI04 / P1 | Cloud, mạng chậm | Gửi đăng nhập rồi bấm tiếp lúc chờ | Hiện đang xử lý, ngăn gửi trùng; thất bại cho thử lại |
| UI05 / P0 | D08 | Chủ đề → tìm Logic → tìm chuỗi không tồn tại → xóa | Kết quả đúng, trạng thái rỗng rõ; xóa trả danh sách |
| UI06 / P1 | D02; bộ lọc Đang học | Bật lọc; tìm chuỗi không tồn tại; xóa tìm kiếm | Giữ bộ lọc và chỉ hiện chủ đề phù hợp |
| UI07 / P1 | Menu → Cài đặt | Chọn nền kem, màu tím, chữ 1.3, giảm chuyển động; quay lại bài | Áp dụng ngay; nội dung đọc được; không mất tiến độ; giảm chuyển động theo lựa chọn |
| UI08 / P1 | Rộng 320/375dp; chữ 1.4; Hồ sơ thử thêm 2.0 | Mở Auth, Chủ đề, Hồ sơ; xoay ngang; mở bàn phím | Không overflow/che nút; tránh tai thỏ/thanh gesture; mục tiêu chạm ngày trong Hồ sơ ít nhất 48×48dp |
| UI09 / P1 | Có hoạt động hôm nay | Chọn hôm qua rồi hôm nay trong Hồ sơ | Ngày/số liệu tương ứng; ngày trống không lấy nhầm tổng ngày khác |
| UI10 / P1 | Bài cân, 3 khối | Kiểm tra sai; thêm khối thứ 4 và kiểm tra lại | Phản hồi sai/đúng đọc được, không chỉ dùng màu; giữ mô hình để sửa |
| UI11 / P1 | Máy có TalkBack | Bật TalkBack, duyệt tab/form/nút kiểm tra/Back | Có tên, vai trò, trạng thái hành động chính; focus hợp lý; ghi lỗi nút thiếu nhãn |
| UI12 / P1 | Menu tại tab Chủ đề | Mở Cài đặt/Giới thiệu/Trợ giúp rồi Back; tìm XP trong Trợ giúp | Trở lại đúng tab; mở được “XP được tính ra sao?”; phiên bản đúng APK |

UI08 là mục tiêu kiểm tra, không phải khẳng định mọi màn hình đều đạt ở mọi cỡ chữ. Test tự động hiện chỉ kiểm tra một số màn hình và màu; TalkBack, bàn phím native và cảm nhận thao tác cần kiểm tra trên máy thật.

## 5. Test luồng chức năng

| ID / mức | Tiền điều kiện / dữ liệu | Bước thực hiện | Kết quả mong đợi |
|---|---|---|---|
| FL01 / P0 | Offline; chưa mở hồ sơ | Tạo hồ sơ bằng tên rỗng, quá dài D07, rồi `  An Demo  ` | Hai dữ liệu sai bị chặn; tên hợp lệ lưu `An Demo` |
| FL02 / P0 | Hồ sơ mới | Chọn Logic và thêm một sở thích; tiếp tục; chọn 10 phút; hoàn tất | Vào Trang chủ; sở thích/mục tiêu lưu; mở lại không bắt onboarding lần nữa |
| FL03 / P0 | D01 | Chủ đề → Logic & quy luật → Vào phòng thí nghiệm; thử 3 khối rồi sửa thành 4 | Sai không hoàn thành; đúng có giải thích và đi tiếp |
| FL04 / P0 | D02 hoặc xong bài 1 | Bài 2 thao tác một phần; Back về Trang chủ; Học tiếp | Đúng bước và trạng thái đã lưu; chưa nhận thưởng hoàn thành chủ đề |
| FL05 / P0 | D01 chưa hoàn thành Logic; ghi XP ban đầu | Làm đủ 6 bài theo đáp án; Hoàn thành hành trình | Màn hoàn thành; đánh dấu chủ đề; XP cá nhân tăng 30 lần đầu; lưu lịch sử |
| FL06 / P0 | D03 | Ôn lại toàn bộ Logic; so XP/lịch sử trước/sau | Có lịch sử ôn tập; không cộng thêm 30 XP lần đầu |
| FL07 / P0 | D02 đã lưu; không đang ghi dữ liệu | Đóng app khỏi đa nhiệm; mở lại; Học tiếp | Giữ hồ sơ và tiến độ trước khi đóng |
| FL08 / P1 | D02, D04 | Đóng phiên & đổi hồ sơ; mở D04 rồi về D02 | D04 không có bài D02; D02 vẫn còn bài; cloud cần đúng tài khoản liên kết |
| FL09 / P1 | D03 | Xem ngày hôm nay và tổng thời gian/XP/lịch sử trong Hồ sơ | Đúng lần học; đổi tab không tự tăng XP; phân biệt XP local/server nếu có |
| FL10 / P0 | Hồ sơ đã lưu | Đăng xuất từ menu; với cloud thử thêm nút Đăng xuất tại chọn hồ sơ/onboarding; đăng nhập account khác | Về Auth; account khác không thấy hồ sơ đã liên kết của account cũ; đăng nhập lại account cũ vẫn còn bài |
| CL01 / P1 | Cloud; D05 | Mật khẩu sai một lần rồi đăng nhập đúng | Lỗi an toàn; đúng vào chọn/tạo hồ sơ |
| CL02 / P1 | Cloud; D06 và hộp thư | Đăng ký; lấy mã mới trong email; xác nhận; gửi lại khi được phép | Vào OTP; mã hợp lệ xác nhận được; cooldown rõ; ghi lại độ dài mã thực tế, không giả định email đến ngay |
| CL03 / P1 | Cloud đã đăng nhập; chưa hoàn thành Logic | Tắt mạng; hoàn thành đủ Logic và lưu; bật mạng; xem trạng thái, Đồng bộ tiến độ ngay nếu cần | Bài local không mất; offline không giả báo XP server; khi server nhận hợp lệ, xử lý hàng chờ và cập nhật XP xác nhận |
| CL04 / P1 | Logic đã được server xác nhận; ghi XP | Đồng bộ hai lần, mở lại app và đồng bộ | Không thưởng trùng; ghi riêng XP local và server trước/sau |
| CL05 / P1 | Cloud; D05, hồ sơ demo | Tài khoản & sao lưu; kiểm tra backup mới; tải danh sách; khôi phục; mở hồ sơ khôi phục | Tiến độ đúng backup; tạo hồ sơ riêng; hồ sơ/bài nháp cũ còn, không tự gộp |
| CL06 / P2 | Hai máy test cùng tài khoản | Đồng bộ cả hai; A sửa thông tin và gửi; B sửa/gửi từ bản cũ; chọn bản giữ nếu báo xung đột | Có lựa chọn khi xung đột; không âm thầm ghi đè; bài/XP xác nhận còn. Không tái hiện được thì ghi BLOCKED và điều kiện |
| CL07 / P2 | Recovery bật, template đã áp dụng | Quên mật khẩu; xác nhận bằng mã tài khoản test; đặt mật khẩu mới, đăng nhập lại | Đổi/đăng nhập được; mã sai/hết hạn không đổi mật khẩu. Flag tắt thì N/A |
| EX01 / P1 | Bản cloud; đăng nhập; chưa chọn AI cá nhân; `tutor-chat` đã triển khai | Trang chủ → chat → gửi câu D10 | Gemini mặc định trả lời thật; không cần API key/Thêm engine; không kỳ vọng văn bản cố định |
| EX02 / P1 | Gemini mặc định hoặc AI cá nhân đã hoạt động | Gửi D10; thử khi mất mạng; bật mạng rồi gửi lại | Có phản hồi khi mạng tốt; lỗi rõ và giữ câu hỏi khi lỗi. Bản offline không có cloud và chưa chọn AI thì hiển thị chưa kết nối |
| EX03 / P2 | Python engine đã thử thành công | Chạy `print(2 + 3)` rồi thử lỗi cú pháp | Stdout có `5` khi thành công; lỗi dễ hiểu, không treo |

CL03–CL04 chọn Logic thuộc baseline có evaluator server theo repository. Local có 71 hoạt động; parity hiện chỉ bao phủ 53 baseline. Không hứa mọi bài local đều đã được publish hoặc xác nhận XP server.

## 6. Lệnh tự động và bằng chứng lần này

Chạy trong PowerShell tại thư mục gốc. Nếu lệnh nào lỗi, lưu log và xử lý trước khi tiếp tục; danh sách lệnh này không tự dừng PowerShell khi một chương trình trả mã lỗi.

```powershell
Set-Location -LiteralPath 'D:\Brilliant Clone\brilliant_mobile\repo-history'
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
dart 'D:\Brilliant Clone\brilliant_mobile\repo-history\tools\check_diverse.dart'
dart 'D:\Brilliant Clone\brilliant_mobile\repo-history\tools\check_depth.dart'
dart 'D:\Brilliant Clone\brilliant_mobile\repo-history\tools\check_space.dart'
node 'D:\Brilliant Clone\brilliant_mobile\repo-history\supabase\tests\evaluator_parity.mjs'
git diff --check
```

Chưa có dependencies thì chạy `flutter pub get` trước. Cần APK cloud thì build tuần tự sau tests, bằng config hợp lệ đã được ignore:

```powershell
flutter build apk --debug --dart-define-from-file='D:\Brilliant Clone\brilliant_mobile\repo-history\config\app.mobile.json'
```

APK: `D:\Brilliant Clone\brilliant_mobile\repo-history\build\app\outputs\flutter-apk\app-debug.apk`. Release cần signing riêng theo README. Không đưa credential E2E vào APK. Cài/chạy đúng APK trên thiết bị demo; build thành công không xác nhận runtime/cloud thật.

Các test liên quan trong `D:\Brilliant Clone\brilliant_mobile\repo-history\test\`: `entry_flow_test.dart`, `home_navigation_test.dart`, `ux_polish_test.dart`, `cloud_backup_test.dart`, `learning_sync_test.dart`, `password_recovery_test.dart`, `daily_activity_test.dart`, `settings_menu_test.dart`, `engine_widgets_test.dart`.

Integration live tại `D:\Brilliant Clone\brilliant_mobile\repo-history\integration_test\phone_readiness_test.dart` cần fixture account/namespace riêng, không chạy chỉ bằng config mobile hay tài khoản cá nhân. Test có network/backup thật và truyền một số đáp án qua callback; không thay thế gesture thủ công. Lần lập tài liệu này không tạo tài khoản hoặc sửa database.

### Kết quả thực thi ngày 28/10/2026

| Kiểm tra | Kết quả lần này |
|---|---|
| Flutter analyze | PASS — `flutter analyze --no-pub`, không có issues |
| Toàn bộ Flutter unit/widget tests | PASS — 197 tests sau bổ sung kiểm tra đăng xuất tại chọn hồ sơ/onboarding; `flutter test --no-pub --reporter expanded`, kết thúc `All tests passed!` |
| Tương tác | PASS — 50 checks |
| Độ sâu bài học | PASS — 2.491 checks |
| Hình học | PASS — 17.552 checks |
| Evaluator server/mobile | PASS — 729 ca / 53 hoạt động |
| Build APK debug có cloud config | PASS — build/cài/chạy bằng `flutter run -d emulator-5554` với `--no-pub` và mobile config |
| `git diff --check` | PASS; hai file Markdown mới cũng đã kiểm tra bằng `git diff --no-index --check` |
| Xem ảnh render từ widget test | Đã xem Trang chủ, bài cân và màn hoàn thành: chữ/nút trong khung, không thấy tràn/chồng ở ba ảnh này; không thay thế runtime thiết bị |
| Emulator sau sửa đăng xuất | Pixel 9: build/cài/mở thành công; đã quan sát màn Đăng nhập/Đăng ký; chưa nhập credential account khác trong lần này |
| Máy thật, email, AI/code provider, backend smoke live | NOT RUN |
| Search design-system của skill UI/UX | Không chạy được: `python` không có trên PATH; tham chiếu checklist, code và test hiện có |

Các lệnh PASS ở trên thực thi trên workspace hiện tại có thay đổi chưa commit. Test Flutter chạy với mock/fixture theo từng test; không chứng minh backend live. Đầu ra đã được quan sát trong phiên chạy công cụ; lần ghi log chuyển hướng trước đó bị gián đoạn và không phải bằng chứng test. Số liệu cũ trong `D:\Brilliant Clone\brilliant_mobile\repo-history\VALIDATION.md` chỉ tham khảo lịch sử.

APK debug x86_64 vừa được Flutter build/cài lên emulator có kích thước **168.097.875 byte**, SHA-256 `19A12FFADF3DA0CA765AA07C2952679151399286B642BE3CD68DB2E97FC13345`, tại đường dẫn APK ở trên. Chưa xác nhận điện thoại vật lý. Không dùng hash này cho bản build lại; build đầy đủ ABI theo lệnh ở trên sẽ có hash/kích thước khác.

Ảnh do suite tạo được giữ tại `D:\Brilliant Clone\brilliant_mobile\repo-history\build\demo-preflight-previews\` (12 PNG). Ảnh là dữ liệu fixture của widget test, không phải bằng chứng cloud hay demo thao tác tay; các ảnh tracked trong docs đã trả về trạng thái trước test để tránh thay đổi ngoài phạm vi.

## 7. Mẫu ghi kết quả và lỗi

Sao chép bảng và thêm một dòng cho từng ID đã chọn. Dùng ảnh `UI01_01.png`, `FL05_before.png`, `FL05_after.png`; video cho kéo/xoay, Học tiếp và offline/online. Không chỉ ghi “app ổn”.

| ID | Dữ liệu/hồ sơ | Kết quả thực tế | Trạng thái | Ảnh/video/log | Lỗi / người test / giờ |
|---|---|---|---|---|---|
| FL05 | Demo_Moi_2810 | XP trước ...; sau ...; số bài ... | NOT RUN | ... | ... |
| CL03 | Tài khoản test, hồ sơ ... | XP local ...; verified ...; hàng chờ trước/sau ...; thông báo ... | NOT RUN | ... | ... |
| UI08 | Thiết bị ..., chữ ... | ... | NOT RUN | ... | ... |

```text
Mã lỗi: BUG-DEMO-001
Ca liên quan / mức độ: ... / chặn demo, nặng, vừa hoặc nhẹ
APK / thiết bị / mạng / thời điểm: ...
Tiền điều kiện / dữ liệu: ...
Bước tái hiện: 1. ... 2. ... 3. ...
Mong đợi: ...
Thực tế: ...
Tần suất: ... lần / ... lần thử
Ảnh/video/log đã che thông tin nhạy cảm: ...
Workaround / người xử lý / kết quả retest: ...
```

Không đưa mật khẩu, OTP, token, API key vào bằng chứng nộp thầy. Che một phần email, giữ thông báo lỗi và số liệu cần chứng minh.

## 8. Điều kiện sẵn sàng demo

- [ ] Mọi P0 áp dụng cho cấu hình demo đã PASS trên đúng APK/thiết bị; N/A có lý do.
- [ ] P1 định trình bày đã PASS; ca chưa chạy được ghi rõ và có phương án bỏ phần đó.
- [ ] Có ảnh trước/sau hoàn thành, video Học tiếp và bảng kết quả thực tế.
- [ ] Tập đủ kịch bản ít nhất một lần; có hồ sơ Logic mới/dự phòng.
- [ ] Cloud/OTP/AI/code chỉ demo live sau khi đã thử thật thành công.
- [ ] Lỗi chặn demo đã xử lý; lỗi còn lại có mô tả/workaround, không đổi thành PASS.

Phiếu chốt: P0 PASS .../...; P1 PASS .../...; FAIL ...; BLOCKED ...; NOT RUN ...; N/A ...; người quyết định demo ...; thời điểm ... .
