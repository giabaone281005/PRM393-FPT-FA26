# Kiểm thử các vai trò và chuẩn bị demo — 21/10/2026

Phạm vi: workspace `D:/DEMO/PRM391`, Supabase phát triển `seoswmcldwwytdrfrrrb` và máy ảo Pixel 9. Các thao tác kiểm thử dùng fixture QA được người dùng cho phép; không sửa thông tin đăng nhập hoặc cấp quyền admin cho tài khoản thật.

## Kết luận và thay đổi

- Trước lần này, dữ liệu đã lưu trên server nhưng chưa có kênh realtime toàn ứng dụng: báo cáo phụ huynh dùng polling, nhiều màn phải mở lại/làm mới; publication chỉ có bảng `payments` legacy.
- Đã nối kênh thay đổi cho dữ liệu gia đình, gói, tiến độ, phiên học, giới hạn học, trang phục, thông báo, hỗ trợ và giao dịch. Các sự kiện gom trong cửa sổ 700 ms rồi tải lại dữ liệu qua repository/RLS/RPC; có tải lại dự phòng 30 giây khi app hoạt động, và tải lại khi quay lại ứng dụng.
- Giáo trình chỉ có quyền đọc một số cột; không đăng ký bảng này trong cùng kênh realtime để tránh làm lỗi toàn kênh. Nội dung bài mới được tải lại dự phòng/khi mở màn, không mở rộng quyền đọc câu trả lời để phục vụ realtime.
- Đã bổ sung thanh toán mô phỏng: tạo đơn demo → nút xác nhận → server ghi paid, mã `DEMO-`, kỳ Plus demo và lịch sử riêng. Không ghi payment merchant giả, không gọi cổng tiền thật.
- Phát hiện và sửa lỗi mở PIN ở phiên B làm mất quyền của phiên A. Hiện mở/khóa chỉ tác động phiên đăng nhập tương ứng; đổi PIN thu hồi mọi token mở khóa cũ.
- Đã sửa việc nhiều yêu cầu tải family state chồng nhau có thể khiến bên gọi chờ xong một yêu cầu bị hủy nhưng role mới chưa được cập nhật. Các lượt tải hiện nối hàng đợi; đổi tài khoản xóa dữ liệu gia đình cũ ngay.
- Bỏ nhãn “Mặc định: 1234” gây hiểu nhầm ở hộp đổi PIN.

## Các bước đã kiểm tra

| Kiểm tra | Kết quả / giới hạn |
|---|---|
| Flutter analyze | Đạt, không có issue ở lượt kiểm tra sau sửa state chồng nhau |
| Toàn bộ Flutter tests | 254 đạt, một test offline được tách theo pipeline |
| Test offline riêng với HTTP loopback | Một test đạt: hàng đợi câu trả lời giải phóng đúng request ID sau sync |
| Node backend tests | 33 đạt; gồm chữ ký, checkout, retry, đối soát, refund, AI và chặn endpoint demo cũ |
| Kiểm tra SQL tĩnh | 37 file đạt ở lần chạy sau khi thêm hai bộ regression mới; không thay thế kiểm thử runtime |
| SQL runtime trên Supabase | Chín bộ regression: commerce, role/learning, session time, learning history, wrong answers, content/payment, family communications, demo payment, parent gate nhiều phiên; đạt và rollback fixture |
| Idempotency hai migration mới | Chạy lại DDL demo/realtime và PIN theo phiên trong transaction rồi rollback: đạt |
| Android — bé học | Đạt: tiếp tục phiên dở → trả lời → hoàn thành → đăng nhập mới vẫn còn lịch sử; ôn lại không nhận XP/sao lần đầu thêm lần nữa |
| Android — phụ huynh nhiều phiên, hỗ trợ, demo và admin | Đạt sau sửa: hồ sơ đổi từ phiên khác cập nhật AppState trong khoảng 2,2 giây (2.217 ms); admin trả lời hỗ trợ phát sự kiện về phụ huynh; nút demo lưu paid, cấp Plus, giữ lịch sử sau đăng nhập mới; admin thấy lịch sử và gia đình khác bị RLS chặn |
| APK debug từ ứng dụng thường | Build đạt, cài và mở thành công trên Pixel 9 |
| Merchant tiền thật / iOS | Chưa nghiệm thu trong lần này |

Các regression SQL chạy trong transaction và hoàn tác thay đổi của fixture. Tài khoản và dữ liệu QA dùng cho kiểm thử Android được tạo có chủ đích và giữ lại để demo theo xác nhận của người dùng.

Đối chiếu dữ liệu QA sau luồng học: tổng thời lượng các phiên **7 giây**, tổng `study_daily_usage` **7 giây**, `family_report.today_seconds` **7 giây**; hai phiên hoàn thành của cùng một bài cho số bài hoàn thành **1**. Thời gian ngắn do bài QA chỉ có hai câu, không phải số thời lượng mẫu. Độ trễ 2.217 ms là một phép đo trong máy ảo ở lượt thử cuối, không phải SLA cho mọi mạng hoặc thiết bị.

## Mức độ đồng bộ theo loại dữ liệu

| Dữ liệu | Lưu ở đâu | Cập nhật giữa phiên/màn |
|---|---|---|
| Hồ sơ bé, quyền Basic/Plus, giới hạn học | Supabase | Sự kiện thay đổi kích hoạt tải lại family state; có dự phòng 30 giây |
| Tiến độ, XP/sao/tim đã được server chốt | Supabase/RPC | Sau thao tác và qua thay đổi hồ sơ/tiến độ; client không tự ghi số dư |
| Trạng thái và thời lượng phiên học | Supabase | Bé gửi heartbeat khoảng 20 giây/lần; sự kiện cập nhật báo cáo/lịch sử; không đảm bảo đổi từng giây ở máy phụ huynh |
| Lịch sử phiên, đáp án và câu sai | Supabase, cache/hàng đợi khi mất mạng | Lịch sử tự tải khi có sự kiện phiên; đáp án chi tiết đọc lại qua RPC khi mở phần xem lại |
| Thông báo, yêu cầu hỗ trợ và phản hồi admin | Supabase | Màn đang mở tải lại sau sự kiện, có kiểm tra account/generation để bỏ phản hồi của phiên cũ |
| Đơn và lịch sử demo | `demo_payment_transactions` | Phụ huynh/admin đọc cùng dữ liệu qua RLS; sự kiện paid và thay đổi subscription kích hoạt cập nhật |
| Thanh toán MoMo/VNPay thật | Sổ merchant hiện có | Màn chờ poll trạng thái; backend merchant còn giới hạn triển khai nêu bên dưới |
| Bài học/giáo trình và CMS bản nháp | Supabase và cache | Tải khi mở màn hoặc dự phòng; không cam kết realtime cho bản nháp/cột nội dung hạn chế |
| Đấu trường, một số màn chi tiết đã mở | Supabase | Theo thao tác/làm mới ở màn tương ứng; chưa chuyển mọi bảng sang push |
| Âm thanh, theme, bé được chọn trên thiết bị | SharedPreferences theo account | Cục bộ; không đồng bộ tùy chọn giữa các thiết bị |
| Bài làm chưa được server nhận | Hàng đợi/cache cục bộ theo account | Chờ kết nối để xác nhận; không trình bày là đã lưu Cloud khi còn pending |

Không kết luận “toàn bộ data realtime 100%”. Nút tải lại vẫn có ích khi mất kết nối, có sự kiện trong lúc màn đang bận hoặc cần kiểm tra dữ liệu vừa thay đổi.

## Thay đổi Cloud

- Áp dụng [migration demo và live sync](D:/DEMO/PRM391/supabase/migrations/20261027000000_demo_payments_and_live_sync.sql). Giữ nguyên bảng merchant/legacy, thêm sổ demo có RLS, helper private và public RPC kiểm tra đăng nhập/PIN/chủ sở hữu.
- Áp dụng [migration PIN theo phiên](D:/DEMO/PRM391/supabase/migrations/20261028000000_parent_gate_session_isolation.sql). Giữ PIN hash và dữ liệu gia đình; chỉ sửa phạm vi token mở khóa và thu hồi token khi đổi PIN.
- Endpoint `demo-pay` cũ đã deploy phiên bản 5, yêu cầu JWT và trả 403 khi được gọi hợp lệ. Không dùng nhánh cũ giả settlement MoMo để cấp Plus nữa. Cấu hình mới lưu trong `supabase/config.toml`.
- Chế độ demo mới bật có thời hạn 48 giờ từ thời điểm áp dụng, dự kiến hết lúc **23/10/2026 01:23 UTC+7**. Kỳ Plus đã cấp vẫn theo thời hạn trong snapshot giao dịch, không tự thu tiền/gia hạn.
- Không áp dụng migration `20261026000000_payment_retention_and_attempts.sql` hoặc triển khai bộ sửa merchant MoMo/VNPay trong lần này. Không coi việc demo chạy được là merchant đã nghiệm thu.

## Bằng chứng và chạy lại

- [Log Flutter đầy đủ](D:/DEMO/PRM391/build/demo-flutter-tests-final.log).
- [Log Android học tập](D:/DEMO/PRM391/build/demo-device-learning.log).
- [Log Android nhiều vai trò](D:/DEMO/PRM391/build/demo-device-roles.log).
- [Log build APK ứng dụng](D:/DEMO/PRM391/build/demo-apk-build.log). APK được build riêng từ `lib/main.dart` với cấu hình app thông thường, không phát hành APK có target integration test hoặc file mật khẩu QA.
- [Kiểm thử Android nhiều vai trò](D:/DEMO/PRM391/integration_test/role_demo_sync_test.dart), [kiểm thử giao diện demo](D:/DEMO/PRM391/test/demo_payment_screen_test.dart).
- [Regression thanh toán demo](D:/DEMO/PRM391/supabase/tests/demo_payment_regression.sql), [regression PIN nhiều phiên](D:/DEMO/PRM391/supabase/tests/parent_gate_multisession_regression.sql).
- Config QA có mật khẩu nằm trong [file bị Git bỏ qua](D:/DEMO/PRM391/build/demo-qa.json); không chép nội dung vào báo cáo hoặc source.

Kiểm thử Android có ghi thay đổi trong tài khoản QA, gồm đổi biệt danh, hỗ trợ và mua demo. Không chạy lại bài test học tập giả định fixture chưa hoàn thành nếu chưa chuẩn bị fixture mới. Bộ test vai trò có thể tạo thêm kỳ Plus demo ở mỗi lần chạy hoàn tất giao dịch mới.

## File thay đổi trong lần này

| Nhóm | File |
|---|---|
| Đồng bộ và state | [account_live_sync.dart](D:/DEMO/PRM391/lib/data/repositories/account_live_sync.dart), [app_state_provider.dart](D:/DEMO/PRM391/lib/data/providers/app_state_provider.dart) |
| Thanh toán demo | [demo_payment_repository.dart](D:/DEMO/PRM391/lib/data/repositories/demo_payment_repository.dart), [commerce_models.dart](D:/DEMO/PRM391/lib/data/models/commerce_models.dart), [demo_payment_screen.dart](D:/DEMO/PRM391/lib/features/subscriptions/demo_payment_screen.dart), [demo_transaction_card.dart](D:/DEMO/PRM391/lib/features/subscriptions/widgets/demo_transaction_card.dart), [learning_packages_screen.dart](D:/DEMO/PRM391/lib/features/subscriptions/learning_packages_screen.dart) |
| Các màn nối cập nhật | [admin_dashboard_screen.dart](D:/DEMO/PRM391/lib/features/admin/admin_dashboard_screen.dart), [admin_commerce_screen.dart](D:/DEMO/PRM391/lib/features/admin/admin_commerce_screen.dart), [content_management_screen.dart](D:/DEMO/PRM391/lib/features/admin/content_management_screen.dart), [notifications_screen.dart](D:/DEMO/PRM391/lib/features/parent_portal/screens/notifications_screen.dart), [support_screen.dart](D:/DEMO/PRM391/lib/features/parent_portal/screens/support_screen.dart), [learning_history_screen.dart](D:/DEMO/PRM391/lib/features/learning_engine/screens/learning_history_screen.dart) |
| PIN và cấu hình | [change_pin_dialog.dart](D:/DEMO/PRM391/lib/features/parent_portal/popups/change_pin_dialog.dart), [config.toml](D:/DEMO/PRM391/supabase/config.toml), [test-sql.ps1](D:/DEMO/PRM391/scripts/test-sql.ps1) |
| Database | Hai migration mới được liên kết ở mục Thay đổi Cloud; hai regression mới được liên kết ở mục Bằng chứng |
| Kiểm thử và fixture | [demo_payment_screen_test.dart](D:/DEMO/PRM391/test/demo_payment_screen_test.dart), [role_demo_sync_test.dart](D:/DEMO/PRM391/integration_test/role_demo_sync_test.dart), [prepare_demo_role_qa.sql](D:/DEMO/PRM391/supabase/operations/prepare_demo_role_qa.sql) |
| Tài liệu | Báo cáo này, [DEMO_SCENARIO.md](D:/DEMO/PRM391/DEMO_SCENARIO.md), [UpdateUserFlow.md](D:/DEMO/PRM391/UpdateUserFlow.md) |

Endpoint `demo-pay` dùng file local đã có từ lần sửa trước để triển khai bản vô hiệu hóa trên Cloud; lần này không thay đổi nội dung file đó. Những thay đổi có sẵn khác trong working tree được giữ nguyên.

## Giới hạn còn lại

- Chưa kiểm thử mọi tổ hợp nội dung của 1.500 câu hỏi, mọi kích thước thiết bị, iOS, merchant thật hoặc tải đồng thời lớn. Kết quả không phải cam kết toàn dự án hết lỗi.
- Cloud còn các rủi ro merchant được ghi trong [báo cáo thanh toán](D:/DEMO/PRM391/supabase/PAYMENT_FLOW_AUDIT_20261020.md) và [bản sửa chờ triển khai](D:/DEMO/PRM391/FIX_REPORT_20261021.md). Buổi demo nên dùng sổ demo mới.
- Security Advisor vẫn báo các helper `SECURITY DEFINER` legacy và leaked-password protection chưa bật. Các helper đã đọc có kiểm tra admin hoặc `auth.uid()`; cảnh báo cần đánh giá tiếp, không kết luận lộ quyền chỉ từ tên cảnh báo. [Hướng dẫn kiểm tra quyền hàm](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable), [bảo vệ mật khẩu rò rỉ](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).
- Các bảng private hoặc bảng sự kiện hệ thống có RLS nhưng không policy đọc cho client là chủ đích chặn đọc; không thêm policy rộng chỉ để xóa cảnh báo Advisor.
- Cơ chế đồng bộ tham khảo [Supabase Postgres Changes](https://supabase.com/docs/guides/realtime/postgres-changes); vẫn cần giám sát độ trễ và kết nối khi vận hành nhiều người dùng.

Kịch bản thao tác trước lớp: [DEMO_SCENARIO.md](D:/DEMO/PRM391/DEMO_SCENARIO.md).
