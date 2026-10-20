# Rà soát MathLingo — 20/10/2026

**Kết luận: còn lỗi.** Bộ kiểm thử có sẵn đạt, nhưng các phép thử bổ sung đã tái hiện lỗi đồng bộ đáp án sau mất mạng và tràn bố cục trên điện thoại hẹp/chữ lớn. Các vấn đề thanh toán đã xác nhận trước đó chưa được sửa. Không coi dự án đã hoàn tất hoặc sẵn sàng production.

Phạm vi: mã Flutter và các nhóm màn hình/tầng repository, Auth/Provider, vòng đời phiên học/cache, parent/admin/content, payment/AI, build Android, metadata/RPC/grants/RLS và các regression trên Supabase phát triển `seoswmcldwwytdrfrrrb`. Không thực hiện giao dịch merchant, gọi AI thật, gửi email, áp dụng migration, sửa quyền/secrets, deploy hoặc push. Các thay đổi ứng dụng có sẵn được giữ nguyên; lượt này chỉ thêm báo cáo/nhật ký và probe trong `build/`.

## Lỗi ưu tiên

### P1 — Câu trả lời tiếp theo có thể bị bỏ qua sau khi tự đồng bộ offline

**Đã tái hiện bằng widget thật + máy chủ giả lập localhost; không kết nối Supabase thật trong probe này.**

Trình tự: trả lời câu 1 khi request lỗi tạm thời → câu trả lời được giữ trong cache → có mạng trở lại, chuyển lifecycle để heartbeat flush hàng đợi → giao diện chuyển sang câu 2 → gửi câu 2. Kết quả: payload câu 2 vẫn mang cùng `p_request` với câu 1 và có thể giữ `_pendingAnswer` của câu 1. Probe xác nhận hai câu khác nhau dùng cùng request ID, trong khi giao diện đã hiện “Chính xác!”.

Nguyên nhân: `D:/DEMO/PRM391/lib/features/learning_engine/study_screen.dart:140` chỉ thay session trong `_apply`; nhánh heartbeat không xóa/bind lại `_answerRequest` và `_pendingAnswer`. Nhánh queued answer tại dòng 250 thoát trước bước reset ở dòng 255. `D:/DEMO/PRM391/lib/data/repositories/study_repository.dart:90` tự flush đáp án trước heartbeat, nên có đường đồng bộ không đi qua nhánh reset của `_answer`.

Backend xử lý request ID đã có theo cơ chế idempotency và trả kết quả lần cũ trước khi chấm câu mới. Vì vậy câu 2 có thể được báo đúng nhưng chưa tạo attempt mới; không đồng nghĩa đã ghi sai số dư hay thưởng ở database.

Hướng sửa: gắn pending submission với session/question/request, reset đúng pending state khi đáp án đó đã được server xác nhận; không reset tùy tiện khi request vẫn chưa chắc chắn để tránh gửi lặp. Cần regression cho sai/đúng, heartbeat/lifecycle flush và retry sau mất kết nối.

Bằng chứng: `D:/DEMO/PRM391/build/project_audit_offline_test.dart`, log `D:/DEMO/PRM391/build/project-audit-offline.log`. Lần chạy cuối chỉ còn lỗi assertion request ID, không còn lỗi plugin/đóng kết nối của harness ở các lần đầu. Đây là probe chủ động tìm lỗi và hiện **FAIL**, không được tính vào 242 test đã đạt.

### P1 — Các vấn đề payment vẫn tồn tại

Chi tiết và bằng chứng database/HTTP ở `D:/DEMO/PRM391/supabase/PAYMENT_FLOW_AUDIT_20261020.md` trong cùng cuộc rà soát ngày 20/10:

1. RPC vẫn cho xóa hẳn đơn pending/failed/expired; đã xác nhận xóa không cần PIN đang mở và callback VNPay muộn sau đó trả không tìm thấy đơn. UI hiện không tự gọi purge/discard khi thoát; vấn đề nằm ở API backend còn tồn tại.
2. MoMo tạo `orderId/requestId` mới theo timestamp khi checkout lại; settlement trả OK cho transaction khác khi đơn đã paid nhưng không ghi thêm transaction đó. Nguy cơ khoản thu thêm bị bỏ qua; chưa thực hiện hoặc khẳng định đã có hai lần trừ tiền thật.
3. Demo đang bật ở development, dùng chung MoMo settlement/payment/kỳ Plus. Phải tách hoặc tắt trước môi trường merchant thật; không thể dùng hai payment hiện tại làm bằng chứng doanh thu thật.

Lượt audit toàn dự án không sửa các vấn đề này, không gọi simulate/merchant hoặc tự thu hồi gói hiện có.

### P2 — Trang chủ và bản đồ tràn bố cục ở màn hình hẹp/chữ lớn

**Đã tái hiện ở 320×700, text scale 1.8, theme sáng, bằng toàn màn hình và state fixture hợp lệ.** Shared progress overview đã có test riêng đạt; điều đó không bảo đảm các hàng/header cũ của toàn màn hình đều đáp ứng.

| Màn/điểm lỗi | Bằng chứng từ RenderFlex |
|---|---|
| Home thông tin bài học, `D:/DEMO/PRM391/lib/features/home/screens/home_screen.dart:172` | Tràn ngang 54 px |
| Home nút tiếp tục, cùng file dòng 258 | Tràn ngang 280 px |
| Header chung, `D:/DEMO/PRM391/lib/features/shared/widgets/app_header.dart:90` | Tràn ngang 103 px; cột dòng 86 tràn dọc 13 px |
| Treasure map header, `D:/DEMO/PRM391/lib/features/treasure_map/screens/treasure_map_screen.dart:179` | Tràn ngang 332 px |
| Các hàng map dòng 363, 431, 799, 895 | Nhiều lỗi tràn ngang, tối đa 462 px trong fixture này |

Probe chạy ba màn: hồ sơ bé đạt cho fixture/khung nhìn đã thử; home và map thất bại. Không suy rộng rằng mọi trang hồ sơ, mọi cỡ chữ hoặc dark mode đã đạt.

Hướng sửa: để text co/đổi dòng, Wrap hoặc đổi bố cục theo constraints; hạn chế kích thước cố định ở header/nút; kiểm tra cả nhãn dài và thanh điều hướng. Không thay bằng màn trống hoặc chỉ test riêng card.

Bằng chứng: `D:/DEMO/PRM391/build/project_audit_responsive_test.dart`; log `D:/DEMO/PRM391/build/project-audit-responsive.log` (**1 đạt, 2 thất bại**).

## Vấn đề xác nhận từ mã/cấu hình, chưa tái hiện E2E trong lượt này

### P2 — Một số màn không xóa thông báo lỗi sau khi tải lại thành công

`D:/DEMO/PRM391/lib/features/admin/content_management_screen.dart:42` và `D:/DEMO/PRM391/lib/features/mascot_wardrobe/screens/mascot_wardrobe_screen.dart:31` chỉ cập nhật dữ liệu khi tải thành công. `_error` được gán khi thất bại, được render tiếp và không được xóa ở đường load thành công. Sau lỗi mạng, màn có thể vừa hiển thị dữ liệu mới vừa tiếp tục báo chưa tải được. Đây là lỗi state hiển thị từ source, không phải bằng chứng backend mất dữ liệu. Chưa chạy device E2E riêng cho hai màn.

### P2 — Thống kê có thể giữ dữ liệu bé trước khi đổi bé

`D:/DEMO/PRM391/lib/features/learning_engine/screens/learning_progress_screen.dart:48` theo dõi `statsRevision`, nhưng không theo dõi ID bé đã tải hoặc `didUpdateWidget` của `kidId`; thao tác `switchKid` không tăng statsRevision. Khi màn còn mounted và bé thay đổi, điều kiện refresh có thể không chạy. Ngoài ra `_loadData` không có generation guard để ngăn response của bé cũ ghi đè response mới. Cần test đổi bé/tài khoản giữa request trước khi đánh dấu đã sửa. Không khẳng định đã có rò rỉ dữ liệu sang gia đình khác; các truy vấn backend có RLS.

### P2 — Đối soát, đề xuất mua và liên kết ví chưa hoàn chỉnh

- Chưa cài `pg_cron`/chưa có `cron.job`; chưa có lịch database gọi reconcile. Scheduler bên ngoài chưa được xác minh. Worker và nút kiểm tra chỉ dùng VNPay, chưa có đối soát MoMo theo provider.
- Danh sách gói dùng giá thật và có phân biệt Basic/Plus/trial, nhưng chưa có bộ đề xuất gói cá nhân hóa theo tài khoản hoặc chủ động ưu tiên đơn pending trước khi mua mới. Đây là khoảng trống tính năng, không gọi là đề xuất thông minh đã hoàn tất.
- Liên kết ví mới lưu/băm số điện thoại người dùng nhập; chưa xác minh sở hữu ví với provider. Không coi trạng thái `linked` là bằng chứng có payment method thật.

### P2 vận hành — Lịch sử migration lệch và thiếu cấu hình release

Repository có **13** file migration; Cloud chỉ ghi **7** version. Nhiều đối tượng runtime có mặt dù version không nằm trong lịch sử, và history slice có version Cloud khác tên timestamp local. Việc 54 RPC literal đều tồn tại không chứng minh schema có thể dựng lại giống Cloud từ migration hiện tại. Không được chạy lại nguyên các migration lịch sử hoặc sửa history theo suy đoán.

`D:/DEMO/PRM391/android/key.properties` không tồn tại ở thời điểm kiểm tra; Gradle có guard yêu cầu signing khi build release. Debug build đạt, chưa có bản release được ký/kiểm thử. Đây là điều kiện phát hành chưa hoàn tất, không phải lỗi làm debug build thất bại.

### P3 — Kiến trúc và bảo trì

Một số thao tác dữ liệu/Auth còn nằm trong widget: `D:/DEMO/PRM391/lib/features/admin/admin_dashboard_screen.dart:249`, `D:/DEMO/PRM391/lib/features/admin/admin_commerce_screen.dart:92`, `D:/DEMO/PRM391/lib/features/auth/account_screen.dart:46`. Cần chuyển đúng repository theo AGENTS khi sửa các luồng này; không suy ra chỉ riêng việc nằm trong widget đã vượt quyền server.

## Kiểm tra Supabase và cách hiểu cảnh báo

- Metadata xác nhận mọi bảng public trong tập kiểm tra đều bật RLS; role client không có SELECT payload câu hỏi thô, không có quyền ghi trực tiếp bảng session/attempt/số dư/payment nhạy cảm. View leaderboard cũ không cấp SELECT cho anon/authenticated. Không kết luận có lộ đáp án chỉ vì còn policy mang tên “Public read”.
- Kiểm tra **54 tên RPC literal** được source Flutter/Edge Functions tham chiếu: không có tên thiếu trong schema public. Chưa coi đây là kiểm thử mọi tổ hợp tham số hoặc mọi nhánh nghiệp vụ.
- **0** bài published không có câu hỏi active; **0** câu hỏi không có skill_id. Nội dung hiện có 1 chủ đề mỗi lớp; lớp 1–4 có 30 bài/300 câu mỗi lớp, lớp 5 có 35 bài/305 câu. Không tự xóa nội dung bổ sung hoặc coi đó là fixture khi chưa có bằng chứng.
- **0** active_kid thuộc sai gia đình/đã archive ở truy vấn consistency; **0** bé có nhiều session trạng thái active. Đây là snapshot, không chứng minh mọi tình huống đồng thời đã được kiểm thử.
- Advisor báo **4 INFO** RLS không policy, gồm bảng private và bảng internal; không tự thêm policy rộng. Các function `SECURITY DEFINER` public được cảnh báo đã được đọc: có UID/role guard hoặc lọc own UID; không xác nhận privilege escalation từ cảnh báo đó.
- Auth đang tắt leaked-password protection: cân nhắc bật trong cấu hình bảo mật khi chuẩn bị vận hành. [Hướng dẫn chính thức](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).
- Performance advisor: 12 FK thiếu index phủ, 2 policy cần initplan, 13 trường hợp policy permissive chồng, 1 cặp index user_roles trùng. Đây là công việc tối ưu/bảo trì, chưa có đo lường chứng minh gây timeout hiện tại. Không xóa index chỉ vì thống kê “unused”. [Index FK](https://supabase.com/docs/guides/database/database-linter?lint=0001_unindexed_foreign_keys), [policy](https://supabase.com/docs/guides/database/database-linter?lint=0006_multiple_permissive_policies), [index trùng](https://supabase.com/docs/guides/database/database-linter?lint=0009_duplicate_index).
- AI `enabled=false`; provider inference, SMTP/deep-link nhận email thật, merchant callbacks và iOS chưa được nghiệm thu. Không gọi cấu hình AI tắt là lỗi crash hoặc tự bật provider trong lượt audit.

## Kiểm thử thực sự chạy trong lượt toàn dự án

| Kiểm tra | Kết quả |
|---|---|
| Flutter analyze | Đạt, không có vấn đề |
| Toàn bộ suite Flutter hiện có | **242 đạt** |
| Backend Node suite | **22 đạt**; có mocks, không phải merchant thật |
| SQL structural checks | **30 file đạt** |
| Android debug với config/app.json | Build thành công, không cài/phát hành |
| 8 suite SQL trên development | Đạt, các suite fixture rollback |
| Probe toàn màn hình hẹp/chữ lớn | **1 đạt, 2 thất bại**: home/map |
| Probe offline answer/heartbeat | **Thất bại** do tái sử dụng request ID ở câu khác |
| Git diff check | Đạt |

8 suite SQL: `commerce_regression.sql`, `role_learning_regression.sql`, `session_time_regression.sql`, `learning_history_regression.sql`, `wrong_answer_review_regression.sql`, `family_communications_regression.sql`, `content_payment_operations.sql`, `legacy_commerce_compatibility.sql`. Suite legacy đọc cấu trúc; các suite ghi fixture đều kết thúc rollback. User đã mở rộng phạm vi sang toàn dự án, nên suite role/content/payment được chạy trong phạm vi mới; không dùng kết quả bị chặn của lượt payment-only làm bằng chứng đạt.

Sau kiểm thử: **0 user fixture regression còn lại**, vẫn **2 đơn paid/2 payments**, không phát hiện active kid sai chủ hoặc session active trùng trong truy vấn sau kiểm tra.

Logs/artifacts: `D:/DEMO/PRM391/build/project-audit-flutter-tests.log`, `D:/DEMO/PRM391/build/project-audit-build.log`, hai probe/log nêu trên. Probe hiện để trong `build/` được Git bỏ qua nhằm giữ mã nghiệp vụ và suite hiện có nguyên trạng trong lượt chỉ kiểm tra; cần chuyển thành regression phù hợp khi thực hiện sửa lỗi.

## Giới hạn và ưu tiên tiếp theo

Đây là rà soát các nhóm chính với automated checks và một số probe mới, không phải chứng nhận mọi màn hình/nút/vai trò đã chạy E2E trên thiết bị. Lượt này không sửa lỗi chức năng.

Ưu tiên sửa: pending-answer state sau offline; bảo toàn đơn và tách demo; idempotency/đối soát MoMo; bố cục home/map/header; state refresh theo bé và xóa lỗi sau retry; sau đó migration reconciliation, signing và các dịch vụ bên ngoài. Cần chạy lại các probe đang FAIL sau khi sửa, không chỉ chạy suite 242 test cũ rồi tuyên bố hết lỗi.
# Cập nhật sau audit

Bản sửa và bằng chứng mới nhất: [FIX_REPORT_20261021.md](D:/DEMO/PRM391/FIX_REPORT_20261021.md). Các nhận định dưới đây giữ nguyên làm bằng chứng trước sửa; phần backend mới chưa được áp dụng lên Cloud do duyệt quyền ghi bị từ chối.
