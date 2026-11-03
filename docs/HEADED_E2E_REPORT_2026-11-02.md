# Báo cáo kiểm thử headed FE–backend — 02/11/2026

## Kết quả chính

**PASS lượt kiểm thử tích hợp sạch trên emulator có giao diện.** Một integration test hoàn tất **34 checkpoint**, đi qua **20 chủ đề / 139 hoạt động**, dùng Supabase Auth, REST/RPC, Edge Functions và Realtime thật.

- Thiết bị: Pixel 9, `emulator-5554`, Android 15 / API 35, x86_64; cửa sổ emulator được mở trong suốt lượt chạy.
- Nền mã: `36bf699` trên `main`, cộng bản sửa lỗi giảm chuyển động được phát hiện trong lượt kiểm thử này.
- Thời gian lượt sạch: **21:17:55–21:30:49, UTC+7**. Tổng thời gian gồm build/cài APK: **774,02 giây**; phần integration test chạy trên Android: **11 phút 54 giây**.
- Kết quả driver: `All tests passed`, exit code `0`; không ghi nhận assertion runtime trong lượt sạch sau bản sửa.
- Kiểm tra hồi quy sau bản sửa: `flutter analyze --no-pub` không có lỗi; **235/235 Flutter test pass** (bao gồm ba ca giảm chuyển động mới).
- Backend handler tests: **21/21 pass**. Kiểm tra độc lập bài học: **50 tương tác, 2.491 độ sâu, 17.552 hình học đều pass**.
- Không dùng mock cho Auth, truy vấn/lưu tiến độ, Gemini, RPC quản trị hoặc kết nối Realtime.

**Giới hạn về cách tương tác:** 92 hoạt động dùng điều khiển qua driver Flutter (tap/drag/nhập liệu) trên emulator. Với 47 hoạt động mô hình cũ, test đưa đáp án công khai qua callback workspace rồi thao tác Kiểm tra/Hoàn thành trên UI. Vì vậy, đây không phải khẳng định cả 139 hoạt động đều được giải hoàn toàn bằng thao tác tay/gesture native.

## Phạm vi và bằng chứng

| Luồng | Kết quả | Đã kiểm chứng |
|---|---|---|
| Đăng nhập | PASS | Form trống; mật khẩu sai bị từ chối; tài khoản thử đúng đăng nhập qua Auth thật. |
| Onboarding | PASS | Tạo một hồ sơ, chọn quan tâm và thời lượng; chuyển vào trang chủ; không có bước chọn nhiều hồ sơ. |
| Trợ lý về app | PASS | Gửi từ UI; FAQ thật trả lời có 20 chủ đề. |
| Gemini | PASS | Gửi câu hỏi học tập từ UI, nhận phản hồi từ Edge/provider thật. Đây là kiểm tra đường truyền/phản hồi, không chấm mọi nội dung AI. |
| Cài đặt | PASS | Đổi màu nhấn, cỡ chữ 1.15 và bật giảm chuyển động; quay lại bằng sự kiện Back của Android. |
| Học bài | PASS | Toàn bộ 20 chủ đề/139 hoạt động có thể render, kiểm tra và hoàn thành; Logic có đáp án sai, gợi ý và thử lại. |
| Tiến độ tự lưu | PASS | Sau mỗi chủ đề, đọc lại snapshot thật và chờ chủ đề xuất hiện trong danh sách hoàn thành trên server. |
| Tổng điểm học local | PASS | Hoàn thành 20 chủ đề, tổng 600 điểm học local; tách biệt khỏi XP được server xác nhận. |
| Idempotency và xung đột | PASS | Gửi lại snapshot không tăng revision; ghi bằng revision cũ với payload khác bị từ chối bằng PT409. |
| XP có thẩm quyền server | PASS | Một phiên Logic thuộc release đã phát hành: 6 attempt được server xác nhận, hoàn thành nhận 30 XP; gửi lại completion không tạo thêm thưởng. |
| Mất mạng thực | PASS | Host tắt Wi-Fi và dữ liệu di động trên emulator; thay đổi bài được giữ; bật mạng lại và xác nhận app tự gửi bản nháp lên server. |
| Hồ sơ và lịch sử | PASS | Có 20 lượt học hoàn thành trong lịch sử sau phần duyệt toàn catalog. |
| Đăng xuất | PASS | Trở lại màn hình tài khoản, phiên đăng nhập cũ không tiếp tục hiển thị trang học. |
| Khôi phục khi đăng nhập lại | PASS | Khởi tạo Auth client mới và namespace SharedPreferences native trống; đăng nhập qua UI, tự lấy lại 20 chủ đề/600 điểm và bản nháp tiếng Anh từ server. |
| Cách ly người dùng | PASS | Học viên không đọc được tiến độ theo owner khác và không gọi được RPC dashboard Admin. |
| Admin | PASS | Đăng nhập bằng Admin thử; đọc dữ liệu thật; chỉ thao tác trên tài khoản/chủ đề thử được đánh dấu. |
| Khóa/mở tài khoản | PASS | Khóa học viên từ UI; RPC học viên bị từ chối; mở lại và đọc tiến độ được, dữ liệu còn nguyên. |
| Quản lý chủ đề | PASS | Tạo chủ đề tạm ở trạng thái nháp, sửa tên rồi lưu trữ; không xuất bản nội dung thử cho học viên. |
| Realtime | PASS | Dashboard native kết nối kênh riêng. Observer độc lập nhận broadcast `accounts` sau cập nhật có kiểm soát trên đúng tài khoản thử; không dùng polling làm bằng chứng duy nhất. |
| Chặn UI Admin | PASS | Tài khoản học viên thấy màn hình không có quyền quản trị. |

### Catalog đã duyệt trên emulator

| Chủ đề | Hoạt động | Chủ đề | Hoạt động |
|---|---:|---|---:|
| Logic | 8 | Địa lý | 4 |
| Phân số | 8 | Triết học | 8 |
| Chuyển động | 7 | Hội họa | 8 |
| Dữ liệu | 8 | Tiếng Anh | 6 |
| Hình học | 8 | Tiếng Việt | 6 |
| Lập trình | 13 | Sinh học | 6 |
| Mạch điện | 7 | Hóa học | 6 |
| Xác suất | 7 | Thiên văn | 6 |
| Đại số | 6 | Tài chính cá nhân | 6 |
| Tối ưu | 5 | Công dân số | 6 |

## Lỗi phát hiện và bản sửa

### Lỗi ứng dụng: AnimatedSize khi giảm chuyển động

Trên Android có giao diện, bật giảm chuyển động rồi mở/đóng gợi ý trong bài Logic làm Flutter báo:

> A RenderAnimatedSize was mutated in its own performLayout implementation.

Khung gợi ý truyền `Duration.zero` cho `AnimatedSize`. Animation có thể hoàn tất đồng bộ ngay trong bước layout và tự đánh dấu layout lại.

Đã sửa nhỏ tại `lib/app_motion.dart` và `lib/journey_app.dart`: wrapper `MotionSize` trả thẳng nội dung khi giảm chuyển động/accessible navigation được bật; chế độ thường giữ chuyển kích thước hữu hạn 240 ms. Không đổi dữ liệu bài học, validator hay luồng lưu tiến độ.

Thêm `test/motion_size_test.dart`: ba ca kiểm tra hai tín hiệu accessibility và hành vi animation thường. Cả ba đã pass; lượt headed sạch sau bản sửa đã đi lại luồng gây lỗi mà không còn assertion.

### Điều chỉnh bộ test và sự cố môi trường

| Lượt trước | Kết quả quan sát | Xử lý |
|---|---|---|
| Lượt 1 | Auth, onboarding, FAQ và Gemini pass; helper `pageBack()` đòi BackButton chuẩn trong khi app dùng header tùy biến. | Dùng sự kiện `handlePopRoute()` để tương ứng Back của Android. |
| Lượt 2 | `pumpAndSettle` hết thời gian vì spinner vẫn chạy trong khi chờ Gemini. | Tách chờ animation hữu hạn khỏi điều kiện hoàn tất HTTP; không bỏ kiểm tra kết quả backend. |
| Lượt 3 | Đã kiểm tra 72 hoạt động; ghi nhận assertion giảm chuyển động; dừng ở một phép đọc xác minh do DNS emulator tạm thời không phân giải được host Supabase. | Sửa lỗi ứng dụng như trên; thêm thử lại có giới hạn cho phép đọc xác minh của test. Ping/DNS emulator sau đó hoạt động lại. |
| Lượt sạch | 139 hoạt động, 34 checkpoint, exit 0. | Kết quả chính của báo cáo này. |

Các lượt trước được lưu riêng, không được tính là những lượt PASS hoàn chỉnh.

## Xác minh backend và dọn dữ liệu

Trước khi dọn, query độc lập xác nhận tài khoản học viên thử có: **1 profile canonical, 1 phiên canonical, 6 attempt, 1 completion verified, 1 dòng thưởng và 1 snapshot tài khoản**. Chủ đề tạm có trạng thái archived. Các số này phù hợp với ca 30 XP có idempotency; không gán XP verified cho 139 hoạt động local.

Sau kiểm thử:

- Thu hồi/xóa phiên của đúng hai fixture trước khi xóa user; dọn chỉ các hàng thuộc UUID đã tạo, có kiểm tra marker định danh.
- Xóa đúng chủ đề tạm sau khi xác nhận không có activity liên kết; không thay đổi 20 chủ đề thật.
- Query độc lập: **0 user thử, 0 chủ đề thử còn lại**; số tài khoản có sẵn vẫn **8**, số chủ đề thật vẫn **20**.
- Fingerprint toàn bộ backup không thuộc fixture giữ nguyên trước/sau: `f2729f86ddf9962cb2784dbc32887ff5`.
- Hai namespace preferences của lượt thử được dọn riêng; không clear dữ liệu app/tài khoản cá nhân.
- Wi-Fi, dữ liệu di động và quyền micro được đưa về trạng thái ban đầu bởi runner.
- Service-role key chỉ dùng trong bộ nhớ host để tạo Auth fixture; không ghi vào source/APK. Mật khẩu fixture chỉ nằm trong cấu hình tạm được ignore và fixture đã bị xóa trên server.
- Hai file cấu hình/manifest chứa thông tin đăng nhập thử đã được xóa sau khi dọn fixture và kiểm tra APK.

### Khôi phục bản app thường sau integration test

Đã build lại debug và release bằng `config/app.mobile.json`, có pub generation, không truyền cấu hình E2E. Quét các entry đã giải nén của cả hai APK: **không còn email, mật khẩu, UUID hoặc run marker của fixture**. APK debug thường đã được cài lại bằng `adb install -r`, giữ dữ liệu app, và mở lại trên emulator; process mới đang foreground, không có lỗi AndroidRuntime/Flutter trong kiểm tra khởi động.

Wi-Fi và dữ liệu di động đều về `1`; quyền RECORD_AUDIO trở về `granted=false`, khớp trạng thái trước test. Release build dùng tùy chọn ký debug dành riêng cho kiểm thử vì máy chưa có release keystore; **không dùng bản release này để phát hành lên store**.

| Artifact thường | SHA-256 |
|---|---|
| `build/app/outputs/flutter-apk/app-debug.apk` | `9e06dbcb60a200a1597582473290c625ba26141edb0544046a8558ca84fd584a` |
| `build/app/outputs/flutter-apk/app-release.apk` | `61555b7df25336e754ea0cc6a1890c87423ed824ae395cec7518d7a889f7e19a` |

## Giới hạn còn lại

- Bấm nút TTS/micro đã được thử; traversal tiếng Anh sử dụng bản chữ/nhập câu để hoàn tất. Log ghi `tts_request=fallback_required`, `microphone_request=unavailable_or_finished`. **Không xác nhận nghe thấy âm thanh, chất lượng nhận dạng hay chất lượng phát âm.**
- Ca “đổi máy” dùng kho preferences native mới và Auth client mới trên cùng emulator; không phải hai điện thoại vật lý.
- Không kiểm chứng giao email OTP, quên mật khẩu qua hộp thư thực, iOS hay thiết bị vật lý.
- 47 hoạt động mô hình cũ dùng fixture đáp án như đã nêu; không coi đây là kiểm thử gesture native đầy đủ cho mọi mô hình.
- Nội dung mới lưu được lên snapshot tài khoản, nhưng chưa đăng ký/publish evaluator mới trên server. XP verified được kiểm tra riêng bằng release Logic đã phát hành; điểm local không phải XP verified.
- Kết quả xác nhận phạm vi đã thực thi, không khẳng định mọi trường hợp có thể xảy ra của app đều đã được kiểm thử.

## Mã và bằng chứng

- Bộ headed test: [full_stack_journey_test.dart](<D:/Brilliant Clone/brilliant_mobile/repo-history/integration_test/full_stack_journey_test.dart>).
- Sửa lỗi: [app_motion.dart](<D:/Brilliant Clone/brilliant_mobile/repo-history/lib/app_motion.dart>), [journey_app.dart](<D:/Brilliant Clone/brilliant_mobile/repo-history/lib/journey_app.dart>), [motion_size_test.dart](<D:/Brilliant Clone/brilliant_mobile/repo-history/test/motion_size_test.dart>).
- Log lượt sạch: [run.log](<D:/Brilliant Clone/brilliant_mobile/repo-history/build/headed-e2e/run.log>).
- Kết quả máy đọc được: [result.json](<D:/Brilliant Clone/brilliant_mobile/repo-history/build/headed-e2e/result.json>).
- Kiểm chứng dữ liệu/dọn fixture: [backend-audit.json](<D:/Brilliant Clone/brilliant_mobile/repo-history/build/headed-e2e/backend-audit.json>).
- Realtime độc lập: [realtime-result.json](<D:/Brilliant Clone/brilliant_mobile/repo-history/build/headed-e2e/realtime-result.json>).
- Log hồi quy: [flutter-regressions.log](<D:/Brilliant Clone/brilliant_mobile/repo-history/build/headed-e2e/flutter-regressions.log>).
- Audit APK: [apk-audit.json](<D:/Brilliant Clone/brilliant_mobile/repo-history/build/headed-e2e/apk-audit.json>); log build thường: `build/headed-e2e/normal-debug-build.log`, `normal-release-build.log`.
- Các lượt trước: `build/headed-e2e/attempt-{1,2,3}.log` và `.json`; là artifact cục bộ, không chứa mật khẩu trong log đã lọc.

Bộ test/sửa lỗi và báo cáo của lượt này chưa được commit hoặc push.
