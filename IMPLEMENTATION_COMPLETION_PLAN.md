# MathLingo — Kế hoạch hoàn thiện tích hợp và triển khai

Ngày: 18/10/2026. Lập theo yêu cầu mới của người dùng, dựa trên kế hoạch nghiệp vụ hiện có và kiểm tra mã/Cloud. Ưu tiên đầu tiên: thời lượng phiên học của bé trên dashboard phụ huynh.

Đây là kế hoạch thực hiện và tiêu chí nghiệm thu. Đã bắt đầu triển khai theo yêu cầu tiếp theo của người dùng; trạng thái thực tế ở phần cập nhật dưới đây. Các thay đổi mã từ đợt audit trước vẫn được giữ nguyên; không pull, reset hay ghi đè.

## Cập nhật triển khai 18/10/2026

- P0: đã sửa refresh báo cáo khi mở/quay lại/resume và mỗi 30 giây; hiển thị giây xác nhận của phiên gần nhất, thời điểm tải và trạng thái heartbeat cũ. Heartbeat được xếp hàng, không bỏ bản ghi pause khi có request đang chạy. Tận dụng schema hiện tại qua repository và RLS. Báo cáo hiện gồm nhiều request, chưa phải snapshot nguyên tử có timestamp server và chưa bổ sung đủ 7 ngày trống.
- Đã chạy: 209 Flutter tests, analyze, 22 Node tests, 25 SQL structural checks; năm bộ SQL hiện có trên Cloud đạt/rollback. Phiên QA thực qua HTTP tăng 122 giây, session và usage khớp. APK debug build/cài/khởi động emulator đạt. Chưa nghiệm thu toàn bộ kịch bản qua nửa đêm, hai thiết bị và đóng tiến trình bất ngờ.
- P2: đã áp dụng migration `20261024000000_cloud_wrong_answer_reviews.sql` lên project `seoswmcldwwytdrfrrrb`. Runtime regression ôn câu sai đạt/rollback: trạng thái ôn là annotation riêng, không sửa điểm/thưởng; RLS, retry, ẩn và mở lại câu sai đều đạt. HTTP qua tài khoản QA Basic/Plus đọc đúng 6/0 bản ghi và chặn truy cập chéo gia đình. Không nhập điểm local cũ thành kết quả xác minh.
- P4: đã đưa truy vấn AI vào repository, đọc trạng thái enabled thật và khóa thao tác khi tắt/chưa tải được cấu hình; không tạo gợi ý giả. `ai-tutor` đã deploy v1 nhưng vẫn tắt và trả 503 do provider chưa sẵn sàng; chưa nghiệm thu inference thật.
- Người dùng đã cho phép áp dụng các migration cần thiết. Sau lỗi phiên ban đầu, apply migration đã thành công. Công cụ tạo version Cloud `20261018102030`; đã kiểm tra MD5 nguồn khớp chính xác file local cộng CRLF cuối (`9ff79b3b594c21b756302eea39020162`) và chỉ đổi version của migration mới này thành `20261024000000`. Không sửa lịch sử các migration 18–23 chưa đối chiếu đầy đủ. Lần apply lại để kiểm tra idempotency DDL gặp lỗi requestState; chỉ idempotency RPC đã được kiểm tra runtime.
- Sau xác nhận riêng của người dùng, đã deploy `ai-tutor` v1, `vnpay-refund` v1 và `commerce-reconcile` v2, đều ACTIVE. Bản đối soát sửa lỗi thiếu job key gây 500: nay thiếu/sai khóa trả 401 trước database/provider; có regression test mới. Smoke HTTP đạt: GET AI/refund 405; refund không đăng nhập 401, phụ huynh 403; đối soát khóa sai 401; AI thiếu cấu hình 503. AI vẫn tắt, không cron, AI/refund requests đều 0; không gửi ảnh/đề hoặc gọi giao dịch/hoàn tiền thật.
- Chưa hoàn tất P1/P3/P5: reconciliation đầy đủ migration history, merchant/SMTP/AI thật, chính sách MoMo/trial, nội dung biên tập và release signing vẫn cần xử lý như các mục bên dưới. Không có dữ liệu người dùng/commerce legacy bị xóa.

## 1. Mục tiêu và phạm vi

- Luồng phụ huynh/học sinh/admin/moderator vận hành với dữ liệu Supabase của đúng tài khoản và đúng bé.
- Thời lượng, tiến độ, điểm, tim, streak, quyền học và giao dịch dùng kết quả do server xác nhận; dashboard đồng bộ sau khi bé học và khi chuyển thiết bị.
- Nội dung bài học có nguồn, trạng thái xuất bản và lịch sử phiên bản; dữ liệu seed được phân biệt với nội dung đã biên tập.
- Không dùng dữ liệu mẫu, giá trị cố định hoặc lỗi bị nuốt để báo nghiệp vụ thành công.
- Cache/outbox hỗ trợ mất mạng và hiển thị rõ trạng thái chưa đồng bộ. Câu hỏi luyện tập sinh từ thuật toán có thể tiếp tục sử dụng nếu được kiểm tra/chấm bởi server; dữ liệu phát sinh hợp lệ không bắt buộc đều là nội dung biên tập sẵn.
- Giữ Flutter/Provider/Repository/Supabase và schema commerce legacy. MoMo/trial đã có mã một phần cần được chốt theo mục 7; không tự mở rộng quyền lợi hay mở bán.

## 2. Bằng chứng về lỗi thời gian

| Điểm đã kiểm tra | Kết quả và ý nghĩa |
|---|---|
| `D:/DEMO/PRM391/lib/features/parent_portal/screens/parent_portal_screen.dart` | Timer 30 giây chỉ gọi `setState`; không gọi tải lại `family_report`. Mở dashboard cũng không chủ động tải báo cáo mới trong `initState`. Đây là lỗi đồng bộ đã xác nhận |
| `D:/DEMO/PRM391/lib/features/parent_portal/screens/parent_dashboard_view.dart` | UI đọc `today_seconds` và làm tròn xuống phút; số dưới một phút hiển thị `<1`. Không có bộ đếm thời lượng của một phiên cụ thể |
| Cloud `private.family_report` | Có tổng thời gian hôm nay/7 ngày; `last_session` chỉ có lesson/title/status/updated_at, thiếu session ID, duration, last heartbeat và dấu thời điểm chụp báo cáo |
| `D:/DEMO/PRM391/lib/features/learning_engine/study_screen.dart` | Heartbeat mỗi khoảng 20 giây khi route hiện tại. Khi `_busy` hoặc đang có heartbeat, lần gửi mới bị bỏ qua; việc rời route/background cần được kiểm thử tích hợp |
| Cloud `private.charge_session` | Chỉ cộng khoảng cách heartbeat trong 0–45 giây; khoảng dài hơn không được cộng. Đây là giới hạn xác nhận hiện tại, cần kiểm thử trước khi quyết định sửa chính sách |
| Dữ liệu Cloud tại thời điểm khảo sát | 11 phiên có tổng `duration_seconds` 1.437 giây; bảng usage cũng có tổng 1.437 giây, nằm ở ngày 17/10/2026. Có một phiên vẫn mang trạng thái `active` từ lần cập nhật cũ. Điều này chứng minh từng có ghi thời lượng, không chứng minh phiên người dùng vừa thao tác đã được ghi đúng |
| Ngày báo cáo | Hôm nay tính theo `Asia/Ho_Chi_Minh`. Tổng ngày 17 không tự chuyển thành “hôm nay” ngày 18; cần hiển thị ngày rõ và kiểm thử qua nửa đêm |
| Test hiện có | `D:/DEMO/PRM391/test/parent_dashboard_test.dart` dùng report truyền vào; chưa chứng minh heartbeat thật khiến dashboard tự cập nhật |

Không cộng bù khoảng mất liên lạc hoặc tái dựng thời gian đã mất bằng đồng hồ thiết bị. Không dùng việc cộng số trên UI làm bằng chứng backend đã lưu.

## 3. Thứ tự thực hiện và điều kiện chuyển giai đoạn

| Mốc | Công việc | Đầu ra bắt buộc / nghiệm thu |
|---|---|---|
| P0 — Thời gian học và dashboard | Tái hiện phiên thật; sửa refresh, lifecycle và hợp đồng báo cáo; đồng bộ thời lượng server | Bộ kiểm thử thời gian ở mục 4 đạt trên SQL, widget và emulator; số dashboard khớp dữ liệu server |
| P1 — Chuẩn hóa Cloud và quyền | Đối chiếu đầy đủ migration/function/policy/grant; phân loại schema drift; kiểm tra Auth/profile/PIN và RLS | Có bảng đối chiếu phiên bản và đường nâng cấp đã thử staging; A không truy cập B; parent/moderator không thực hiện tài chính/admin |
| P2 — Hoàn thiện dữ liệu học | Kiểm kê mọi nguồn dữ liệu local/mock; đồng bộ dữ liệu cần bền vững; chuẩn hóa nội dung và báo cáo | Mở lại app/đổi thiết bị giữ đúng tiến độ; không thưởng lặp; nội dung mở khóa/Plus đúng; không ghi nhận kết quả từ client tự khai |
| P3 — Commerce và vận hành | Hoàn thiện VNPay, đối soát/refund/support; xử lý MoMo/trial theo phạm vi đã chốt | Sandbox chứng minh một thanh toán/một kỳ quyền; callback lặp, pending, refund, hết hạn và hạ gói đều đúng |
| P4 — AI và thông báo lỗi | Hoàn thiện trạng thái bật/tắt, repository, quota và triển khai AI đã được duyệt | OCR → sửa đề → gợi ý với provider thật; retry không tính lượt lặp; khi tắt/thiếu cấu hình có thông báo rõ |
| P5 — Phát hành và nghiệm thu | Regression toàn hệ thống, cấu hình ký, build release, thử thiết bị và kịch bản vận hành | Bộ kiểm thử ở mục 6 đạt; build release có chữ ký; mọi phần chưa bật được trình bày đúng trong app/tài liệu |

Thứ tự ưu tiên này tiếp nối kế hoạch hiện có; không chuyển sang mở bán/AI trước khi các luồng học, thời gian và quyền đạt nghiệm thu. Không dùng kết quả test của lần audit trước thay cho việc kiểm thử các thay đổi mới.

## 4. Chi tiết P0 — Sửa thời lượng phiên học

### 4.1. Quy ước dự kiến

- “Thời gian học” tính lúc bé đang ở màn học/luyện tập/đấu trường có phiên server hợp lệ và app ở foreground; có tính thời gian đọc lý thuyết.
- Thời gian ở cổng phụ huynh, nền/khóa màn hình, màn khác và chờ mất mạng chưa xác nhận được tách khỏi thời gian học đã xác nhận.
- Minigame giải trí và ôn câu sai local hiện chưa nằm trong vòng heartbeat server. Phải ghi rõ phạm vi này; nếu sản phẩm muốn tính toàn bộ thời gian dùng app thì cần thêm chỉ số “thời gian sử dụng”, không trộn vào `duration_seconds` của phiên học.
- Nguồn chuẩn là giây ở server. Dashboard hiển thị riêng: thời lượng phiên gần nhất, tổng hôm nay, tổng 7 ngày, giới hạn/ngày và thời điểm đồng bộ.
- Dashboard cập nhật theo nhịp dự kiến 20–30 giây khi đang mở/foreground, và cập nhật ngay khi quay lại từ luồng học hoặc mở cổng phụ huynh. Không đặt mục tiêu đồng bộ từng giây qua mạng.

### 4.2. Tái hiện trước khi sửa

1. Dùng tài khoản QA có sẵn; ghi lại child/session ID và thời điểm UTC cùng ngày Việt Nam, không ghi password/token vào log.
2. Học liên tục khoảng 2 phút; quan sát request heartbeat, response và `study_sessions.duration_seconds`/`study_daily_usage`.
3. Thoát giữa bài, vào dashboard cùng thiết bị rồi mở dashboard ở thiết bị khác; đối chiếu dữ liệu server và thời điểm tải report.
4. Phân biệt lỗi không ghi server, lỗi không tải report, sai child/ngày và lỗi định dạng thời gian. Chỉ thay SQL khi có tái hiện yêu cầu sửa SQL.

### 4.3. Backend và hợp đồng dữ liệu

- Tận dụng `study_sessions`, `study_daily_usage` và RPC hiện có; không tạo bảng thời gian trùng chức năng.
- Báo cáo cần trả thời điểm server/ngày báo cáo; thời lượng hôm nay theo giây; đủ 7 ngày kể cả ngày không học; giới hạn của từng bé ngay trong report.
- Bổ sung thông tin phiên gần nhất gồm ID, kind, status, started_at, updated_at, last_heartbeat_at và duration_seconds đã xác nhận. Phân biệt phiên có heartbeat mới với bản ghi `active` đã cũ.
- Giữ kiểm tra sở hữu, slot/quyền học, khóa nguyên tử và giới hạn mỗi ngày. Kiểm thử hai thiết bị và heartbeat/finish trùng trước khi cần thêm cơ chế kiểm soát thiết bị.
- Kiểm tra phân bổ giây qua nửa đêm, pause/resume, đóng app, ngân sách ngày và phần giây lẻ. Không tự tăng ngưỡng 45 giây để làm dashboard có số.
- Nếu cần thay RPC/schema: tạo migration mới qua CLI, forward-only, idempotent; thử trên staging và chạy lại hai lần để xác minh. Không sửa migration 18–23 hoặc ghi lịch sử “applied” chỉ dựa vào tên bảng.

### 4.4. Flutter và dashboard

- `D:/DEMO/PRM391/lib/data/repositories/study_repository.dart`: phối hợp heartbeat và thao tác trả lời/hoàn tất; giữ cùng request ID khi retry; lỗi được phân loại rõ.
- `D:/DEMO/PRM391/lib/features/learning_engine/study_screen.dart`: tạm dừng/tiếp tục theo lifecycle và route; gửi phần thời gian cuối khi rời màn trong khả năng lifecycle cho phép; không phụ thuộc hoàn toàn vào `dispose` để lưu.
- `D:/DEMO/PRM391/lib/data/providers/app_state_provider.dart`: có thao tác tải báo cáo riêng, tránh kéo lại toàn bộ curriculum/wardrobe mỗi nhịp; chống request chồng, kết quả cũ ghi đè, nhầm tài khoản/bé và cập nhật sau dispose.
- Repository/model báo cáo phụ huynh: gom truy vấn/parse vào tầng data, giữ đơn vị giây; cache có thời hạn và ghi rõ thời điểm đồng bộ. UI không tự ghi số giây vào Cloud.
- `D:/DEMO/PRM391/lib/features/parent_portal/screens/parent_portal_screen.dart`: tải report khi mở, sau unlock, khi resume/quay lại; refresh định kỳ thực sự gọi data layer; dừng khi rời màn/khóa cổng/background.
- `D:/DEMO/PRM391/lib/features/parent_portal/screens/parent_dashboard_view.dart`: hiển thị tổng hôm nay và thời lượng phiên riêng; không thể hiện dữ liệu cache cũ như một phiên đang chạy; dùng theme hiện có.

### 4.5. Bộ nghiệm thu thời gian

| Tình huống | Kết quả cần chứng minh |
|---|---|
| Học 2 phút online, foreground | Duration và usage tăng gần thời gian thực, sai lệch trong một nhịp heartbeat khi đang học; sau flush hợp lệ phải khớp số server |
| Đọc lý thuyết, chưa trả lời | Vẫn ghi thời gian nếu nằm trong phạm vi phiên hợp lệ |
| Thoát trước khi đủ 20 giây | Có kiểm thử phần cuối phiên, không mặc định bỏ toàn bộ phiên ngắn |
| Khóa màn hình/background 1 phút | Thời gian nền không cộng vào học; quay lại tiếp tục đúng ngân sách |
| Mất mạng rồi kết nối lại | Không cộng giả khoảng không xác nhận; UI báo chờ đồng bộ; retry không cộng trùng |
| Hai thiết bị/cùng bé | Không cộng hai lần cùng khoảng thời gian; trạng thái resume nhất quán |
| Qua 00:00 giờ Việt Nam | Mỗi ngày nhận đúng phần giây; tổng 7 ngày và ngân sách ngày mới đúng |
| Hết giới hạn hoặc đổi giới hạn | Server chặn/cho học theo quyền hợp lệ; dashboard tải đúng giới hạn của bé đang xem |
| Chuyển bé/đổi tài khoản | Không hiển thị hoặc nhận response thời gian của bé/tài khoản trước |
| Dashboard đang mở trên thiết bị khác | Nhìn thấy dữ liệu đã xác nhận sau một chu kỳ refresh, không cần đóng/mở app |
| Phiên `active` quá cũ | Không hiển thị bé “đang học” chỉ từ cột status |

Đo trước/sau trên các fixture riêng; không sửa số thời gian của gia đình thật để tạo kết quả đạt.

## 5. Chi tiết phần còn lại

### P1 — Database, Auth, phân quyền

- Kiểm tra bản sao/staging/backup có thể phục hồi trước thay đổi Cloud. Phân loại rõ môi trường đích.
- So sánh local migrations, repair SQL và định nghĩa Cloud, gồm các đối tượng trial/MoMo/legacy. Ghi rõ đối tượng tương đương, lệch và thiếu; chỉ sửa history khi đủ bằng chứng.
- Xác minh đăng ký → xác minh email → tạo family → PIN → thêm bé → đăng xuất → khôi phục mật khẩu. Kiểm thử deep link khi app đóng/đang mở và email bị giới hạn gửi.
- Kiểm tra phân quyền row, column, RPC, private helper; không cấp SELECT toàn bộ câu hỏi để sửa màn hình.
- Rà cảnh báo advisors và bảo vệ mật khẩu theo khả năng dự án; không xóa policy hoặc mở quyền chỉ để làm mất cảnh báo.

### P2 — Học tập, nội dung, dữ liệu bền vững

- Lập danh sách từng nguồn local/hardcoded và nơi sử dụng, phân thành cấu hình/UI, cache, dữ liệu luyện tập sinh hợp lệ, nội dung seed và dữ liệu nghiệp vụ cần Cloud.
- Kiểm thử từ bắt đầu đến hoàn tất/tiếp tục bài: đúng/sai, gợi ý, tự luận, hết tim, hồi tim, thưởng, mở khóa, streak, số liệu phụ huynh và quyền Plus.
- Với lịch sử câu sai cần đồng bộ: thiết kế theo attempts server và snapshot an toàn, có quyền sở hữu/phiên bản nội dung. Không tải đáp án của toàn bộ nội dung Plus ngoài quyền. Dữ liệu local cũ chỉ nhập theo chính sách rõ; không biến điểm client tự khai thành kết quả đã xác minh.
- Biên tập lại 50 nhóm câu hỏi lặp và xử lý hai tập số bài lớp 5 bằng version/CMS; giữ liên kết attempts/progress cũ. Kiểm tra đáp án toán và độ phù hợp từng lớp.
- Đấu trường/tủ đồ được nghiệm thu bằng session và giao dịch server, gồm yêu cầu đồng thời; minigame giải trí không tự cấp XP/sao.

### P3 — Gói học, thanh toán, hỗ trợ

- Hoàn thiện vòng VNPay đã nằm trong kế hoạch: catalog/giá phiên bản → order → checkout → IPN/query → payment → entitlement → lịch sử/khôi phục.
- Chuẩn bị ba chức năng thiếu trên Cloud: refund, reconcile và AI ở P4. Deploy và bật scheduler là bước riêng cần phép; không gửi giao dịch/hoàn tiền thật trong kiểm thử mặc định.
- Chạy sandbox: hủy/pending, mạng mất sau trả tiền, webhook trước callback, chữ ký/số tiền sai, callback lặp 5 lần, gia hạn nối kỳ, hết hạn, downgrade, refund timeout/unknown và đối soát.
- Support/thông báo phải theo đúng order/gia đình, không tạo trạng thái thành công giả.
- MoMo và trial chỉ triển khai trọn vòng sau khi xác nhận sản phẩm. “Gắn ví” phải có xác minh provider nếu được dùng làm điều kiện chống dùng thử lặp; nhập số điện thoại và hash không chứng minh sở hữu ví.

### P4 — AI

- Chuyển gọi AI về repository phù hợp; giữ chọn/chụp ảnh ở UI, xử lý loading/error/disabled rõ.
- Cấu hình key/model qua secrets; quota theo gia đình/gói, idempotency/rate limit; kiểm thử ảnh hợp lệ, ảnh không đọc được, đề đã sửa, provider lỗi và nhiều lần retry.
- Chỉ bật quyền lợi AI sau thử provider thật và duyệt cách xử lý dữ liệu ảnh/đề. Không coi output AI là đáp án toán đã được chứng minh.

### P5 — Release

- Rà trạng thái feature flag, cấu hình môi trường, merchant sandbox/production, redirect, signing, logs và tài liệu vận hành.
- Cấu hình keystore do chủ dự án quản lý; không bỏ guard ký hoặc dùng khóa debug cho release.
- Nghiệm thu Android và iOS nếu nằm trong kênh phát hành đã chốt. Build có chữ ký, cài mới/nâng cấp, đa thiết bị, mạng yếu, cỡ chữ lớn và chế độ nền.
- Có cách tắt mở bán/AI/job khi lỗi mà vẫn bảo toàn quyền đã mua, dữ liệu học và callback đang xử lý.

## 6. Cổng kiểm thử bắt buộc

Sau mỗi mốc sửa mã: formatter đúng file, `flutter analyze`, test liên quan, `git diff --check`; cuối vòng chạy toàn bộ Flutter/Node/SQL checks và build theo `D:/DEMO/PRM391/.github/workflows/verify.yml`.

SQL/RPC thay đổi cần runtime regression, RLS A/B, kiểm thử idempotency và migration trên staging. Kiểm thử Node mock không thay cho provider thật; widget với report giả lập không thay cho luồng heartbeat → database → dashboard.

Mỗi mốc bàn giao phải có: file/object đã đổi, nguyên nhân, bằng chứng trước/sau, test đạt/thất bại/bỏ qua và lý do. Chỉ ghi “hoàn tất” khi tiêu chí mốc tương ứng đã chạy đạt. Kết quả audit trước là baseline, không phải chứng nhận release.

## 7. Các quyết định/phụ thuộc trước khi triển khai Cloud

| Nội dung | Mặc định dùng để bắt đầu phần local | Điểm cần chốt trước thao tác phụ thuộc |
|---|---|---|
| Phạm vi đếm thời gian | Phiên học/luyện/đấu trường foreground; thời lượng server xác nhận | Nếu muốn đếm toàn bộ app/minigame, xác nhận thêm chỉ số sử dụng và quy tắc giới hạn |
| Cloud rollout | Chuẩn bị/sửa mã và test local, script/migration mới | Cho phép deploy/apply lên môi trường đích sau khi kết quả cụ thể đã sẵn sàng duyệt |
| MoMo/trial | Giữ dữ liệu và API hiện có, không quảng bá thêm quyền lợi | Tiếp tục VNPay MVP hay nghiệm thu thêm MoMo/trial; chính sách trial/xác minh ví/hoàn tiền |
| Email, payment, AI | Không ghi secret vào source hoặc báo cáo | SMTP, tài khoản merchant/provider và quyền thực hiện giao dịch sandbox/thật |
| Release | Debug QA trước | Upload keystore và nền tảng/kênh phát hành được chọn |

Không cần chờ các quyết định commerce/AI để bắt đầu P0. Yêu cầu lập kế hoạch này không được coi là quyền deploy, mở bán, hoàn tiền, reset dữ liệu hoặc áp migration lên production.
