# MathLingo — Phân tích hiện trạng và kế hoạch nâng cấp

Ngày đánh giá: 16/10/2026. Phạm vi: mã Flutter, repository, migration/seed SQL, cấu hình Android/iOS và bộ kiểm thử trong checkout hiện tại.

## 1. Kết luận

MathLingo có nền tảng giao diện và các phân hệ khá đầy đủ cho đồ án: học toán tương tác, lộ trình lớp 1–5, vườn luyện tập, đấu trường, hồ sơ bé, cổng phụ huynh, tủ đồ, quản trị và gói Basic/Plus. Tuy nhiên, mức hoàn thiện giao diện đang cao hơn mức hoàn thiện nghiệp vụ và dữ liệu. Dự án phù hợp để tiếp tục hoàn thiện thành MVP; chưa có đủ bằng chứng để coi là sẵn sàng vận hành thực tế.

Ưu tiên: sửa xác thực và phân quyền → bảo toàn dữ liệu theo tài khoản → hoàn thiện vòng học và phần thưởng → đo lường học tập → offline thật → OCR/AI và các tính năng mở rộng.

Người dùng đã xác nhận toàn bộ migrations trong repository đều đã chạy trên Supabase. Vì vậy, kế hoạch coi schema sau migration cuối cùng là hiện trạng đang triển khai, bao gồm policy đọc mọi kid_profiles cho authenticated. Chưa truy vấn Cloud độc lập để kiểm tra thay đổi ngoài migrations. Không thực hiện đăng nhập tài khoản demo, đọc dữ liệu người dùng thật hoặc sửa Cloud. Kế hoạch bổ sung theo vai trò và bán gói: [ROLE_COMMERCE_DEVELOPMENT_PLAN.md](ROLE_COMMERCE_DEVELOPMENT_PLAN.md).

## 2. Hiện trạng các phân hệ

| Phân hệ | Đã có | Phần chưa hoàn thiện |
|---|---|---|
| Kiến trúc | Feature-first, model, repository, Provider, theme | AppStateProvider gộp nhiều trách nhiệm; repository static khó thay thế trong test; lỗi thường bị nuốt |
| Xác thực | Gọi Supabase Auth, UI đăng nhập/đăng ký/OTP | OTP giả lập, nhánh thành công không cần phiên hợp lệ, quên mật khẩu chưa xử lý, thiếu điều hướng theo phiên |
| Hồ sơ bé | Tạo/đọc/xóa, chuyển hồ sơ | Sửa tên/lớp chưa gửi lên Cloud; lỗi tạo bị biến thành thành công cục bộ; thiếu trạng thái tài khoản chưa có bé |
| Giáo trình | Có LessonRepository đọc Cloud, seed sinh 150 bài × 10 câu, fallback local | Không khôi phục tiến độ riêng từng bé; truy vấn tuần tự; nội dung lặp nhiều, chưa đủ đa dạng theo từng bài |
| Học tập | Lý thuyết, quiz, tự luận, mini game, 5 widget câu hỏi | Chưa chặn bỏ qua bước; tự luận chỉ kiểm tra có đáp số; chưa ghi phiên/lượt trả lời thực tế |
| Tim và streak | Trừ/hồi tim, lưu tiến độ và streak | Streak tăng theo bài thay vì ngày; độ chính xác cố định 100%; thưởng thiếu cơ chế chống nhận lặp |
| Đấu trường | Đọc/ghi điểm, hai trò chơi | Chưa chia nhóm 30 thành viên thật; ISO week chưa xử lý giao năm; điểm tăng phía client; lỗi có thể bị thay bằng BXH mẫu |
| Tủ đồ | UI mua/trang bị, lưu avatar_id | Chưa nối inventory/equipment và RPC purchase_item đã có trong SQL; mua và trừ sao chưa thành một giao dịch |
| Cổng phụ huynh | PIN/câu đố, giới hạn thời gian, thanh kỹ năng | PIN không hash và không đọc lại từ Cloud; số kỹ năng cố định; chưa thấy bộ đếm và chặn hết thời gian |
| Admin và Plus | Danh sách phụ huynh, bộ lọc, RPC đổi gói, audit SQL | Nhận diện admin theo email ở client; trial chỉ thay state cục bộ; hạn dùng chưa được áp dụng nhất quán |
| AI Scanner | UI quét và bài mẫu Socratic | Chưa camera/OCR/model; chưa xử lý ảnh, chất lượng nhận diện, hạn mức, chi phí |
| Kiểm thử/phát hành | 3 widget test, cấu hình nền tảng | Chưa có integration test, SQL test, CI; Android release thiếu INTERNET trong manifest chính, đang ký bằng debug key |

Các file chỉ `export 'screens/…'` là alias tương thích, không nên coi tất cả cấu trúc thư mục lặp tên là mã triển khai trùng.

## 3. Các vấn đề cần xử lý trước

P0: cản trở sử dụng dữ liệu thật an toàn. P1: nghiệp vụ chính sai hoặc mất dữ liệu. P2: nâng chất lượng trải nghiệm và mở rộng.

### P0 — Xác thực, phân quyền và cách ly tài khoản

1. **Đăng nhập có nhánh báo thành công khi không có xác thực hợp lệ.** `lib/data/repositories/auth_repository.dart`: khi Supabase chưa khởi tạo, đăng nhập/đăng ký trả success; một số email mẫu cũng trả success kể cả đăng ký dự phòng thất bại. `auth_screen.dart` điều hướng admin dựa trên email người dùng vừa nhập. Đây là khả năng đi qua cổng giao diện; chưa đủ bằng chứng khẳng định vượt được RLS/RPC trên Cloud. Cần bỏ nhánh này khỏi bản dùng thật, có chế độ demo riêng và chỉ chuyển màn hình khi có phiên hợp lệ.

2. **OTP không xác minh email thật.** `auth_screen.dart` tạo mã từ thời gian trên thiết bị; `otp_verification_dialog.dart` so sánh cục bộ và chấp nhận `123456`. Cần dùng luồng xác minh do Supabase Auth cung cấp, phân biệt đăng ký chờ xác minh với đăng nhập thành công; thêm resend, hết hạn và xử lý liên kết quay về ứng dụng.

3. **SQL mở lại quyền đọc mọi hồ sơ bé cho authenticated.** Migration `20261017000000_admin_and_subscriptions.sql` tạo policy tên “Admins can view all kid profiles” nhưng có `USING (true)`. `KidRepository.fetchKids()` lại select toàn bảng, không lọc parent_id. Nếu migration này được áp dụng và role có quyền SELECT, phụ huynh có thể đọc hồ sơ gia đình khác và app có thể nạp chúng. Cần giới hạn sở hữu hoặc admin thực sự; leaderboard dùng tập trường tối thiểu riêng. Kiểm tra với hai tài khoản phụ huynh và một admin.

4. **State không được thay/reset theo vòng đời phiên.** Provider đồng bộ lúc khởi tạo; luồng đăng nhập không gọi refresh và không thấy listener auth. Cloud trả danh sách rỗng thì giữ danh sách bé trước đó; đăng xuất chỉ khóa cổng, chưa xóa hồ sơ/Plus/trang phục/tiến độ khỏi Provider. Cần AuthState rõ ràng, reset khi đổi tài khoản, và trạng thái “chưa có bé” thay vì giữ mẫu/dữ liệu cũ.

5. **PIN phụ huynh chưa có bảo vệ phù hợp.** `_parentPin` mặc định `1234`, mã PIN mới được ghi nguyên văn vào cột mang tên `parent_pin_hash`, không thấy nạp lại PIN. Cần thiết lập PIN ban đầu, xác minh an toàn ở backend, giới hạn thử sai và tự khóa cổng khi rời chế độ phụ huynh/đưa app ra nền. Câu đố toán học chỉ là cổng hạn chế thao tác; không dùng thay xác thực cho hành động tài khoản nhạy cảm.

### P1 — Dữ liệu và nghiệp vụ học tập

6. **Tiến độ được gán sẵn.** `LessonRepository.fetchLessonsForGrade()` coi bài trước 14 đã hoàn thành, bài 14 đang học; không đọc `kid_progress`. Cần tải tiến độ theo kid_id, khôi phục sao và mở khóa theo quy tắc rõ ràng. Tài khoản mới bắt đầu từ bài đầu.

7. **Sửa hồ sơ chỉ thay trong RAM.** `AppStateProvider.updateKidProfile()` gọi `updateKidStats(id)` không truyền nickname/grade; repository chỉ cập nhật updated_at. Tách thao tác sửa hồ sơ và phản hồi thành công sau khi lưu. Xóa bé phải kiểm tra kết quả repository trước khi xóa local.

8. **Lỗi Cloud bị che thành dữ liệu mẫu/thành công.** Nhiều catch trả rỗng/null hoặc bỏ qua; createKid thất bại vẫn tạo ID dạng `kid-…` không tương thích UUID database. Cần kết quả phân biệt thành công/rỗng/mất mạng/không có quyền; dữ liệu demo không ghi lên Cloud. Cho phép retry và thể hiện trạng thái chưa đồng bộ.

9. **Có thể bỏ qua điều kiện hoàn thành.** Các tab học cho chuyển tự do, nút nhận thưởng luôn mở; `_essayDone` và `_miniGameWon` chưa dùng để quyết định hoàn thành. Thắng mini game gọi completeLesson; completeLesson chưa chặn thưởng lặp, tham số XP chưa được sử dụng và accuracy luôn 100. Cần máy trạng thái phiên học, thống kê trả lời thật và hoàn tất một lần cho mỗi phiên có ID duy nhất.

10. **Streak chưa đúng theo ngày.** Mỗi bài trước 21h tăng streak một lần; chưa xét cùng ngày, ngày kế tiếp hay bỏ ngày. KidProfile.fromJson cũng không nạp streak từ kid_streaks. Cần chốt định nghĩa mốc 21h, dùng múi giờ Asia/Ho_Chi_Minh và thời gian server; học nhiều bài/ngày không tăng nhiều ngày.

11. **Thời gian học và báo cáo chưa có dữ liệu thật.** `usedScreenTimeMinutes` chỉ khởi tạo; chưa thấy cập nhật thời gian hoạt động hoặc kiểm tra khóa. Thanh kỹ năng dùng 92%, 85%, 68%, 58% cố định. SQL đã có study_sessions/question_attempts nhưng app chưa nối. Cần ghi thời lượng foreground, lượt trả lời, gợi ý đã dùng và tính báo cáo theo bé/ngày/kỹ năng.

12. **Tủ đồ chưa dùng mô hình sở hữu.** App chỉ trừ sao rồi ghi avatar_id riêng, không gọi purchase_item hoặc lưu inventory/equipment. Cần dùng giao dịch mua ở server, trang bị chỉ đồ đã sở hữu và không thu lại sao khi trang bị lại. RPC hiện có vẫn cần kiểm tra đồng thời, quyền cập nhật trực tiếp và tính toàn vẹn trước khi dùng làm nguồn kiểm soát kinh tế.

13. **Đấu trường chưa thực hiện nhóm 30.** UNIQUE(grade, week_code) tạo một giải cho cả khối; limit(30) chỉ giới hạn số hàng trả về. Cần mô hình giải/nhóm/thành viên, quy tắc xếp nhóm và thời điểm chốt giải. Tăng XP trong giao dịch, chống gửi lại kết quả; tính ISO week-year đúng tại giao năm. Rà lại upsert theo khóa ghép kid_progress/tournament_members, khai báo mục tiêu xung đột phù hợp.

14. **Plus thiếu nguồn quyền lợi thống nhất.** UI trial chỉ updateLocalSubscription; addKidProfile chặn cứng 3 trong khi Basic có maxKids=1. Trigger database đọc max_kids nhưng chưa xét status/expires_at. Cần tính quyền lợi hiệu lực ở server, đồng bộ mọi màn hình, xử lý hết hạn/hạ gói mà vẫn giữ dữ liệu bé. Chốt BR-04 là mọi tài khoản tối đa 3 hay Basic 1/Plus 3 và cập nhật tài liệu nhất quán.

15. **Android release chưa đủ cấu hình.** INTERNET chỉ nằm trong manifest debug/profile; manifest main chưa khai báo, có nguy cơ bản release không gọi được Supabase. Release đang ký debug key. Cần kiểm thử bản APK/AAB release trên thiết bị, cấu hình ký riêng và tách môi trường demo/staging/production.

## 4. Các phần nên bổ sung

| Hạng mục | Phạm vi đề xuất | Tiêu chí hoàn thành |
|---|---|---|
| Khôi phục tài khoản | Quên mật khẩu, xác minh email, đổi mật khẩu và khôi phục phiên | Luồng hoàn chỉnh từ email đến app; token hết hạn báo đúng |
| Onboarding thật | Phụ huynh tạo bé đầu tiên, chọn lớp, đặt PIN | Tài khoản mới không nhận sẵn Bé Bo/Bé Bắp hoặc 13 bài đã xong |
| Lịch sử học | Phiên, câu trả lời, thời lượng, sai ở kỹ năng nào | Màn hình lấy số liệu từ phiên thật; trạng thái chưa có dữ liệu rõ ràng |
| Luyện tập thích ứng | Ưu tiên câu đã sai, đánh giá ban đầu, ôn theo kỹ năng | Giải thích được vì sao đề xuất bài; xác minh bằng lịch sử đã ghi |
| Quản trị nội dung | Quản lý chủ đề/bài/câu hỏi, xem trước widget, nháp/xuất bản | Kiểm tra payload/đáp án trước xuất bản; có phiên bản nội dung |
| Offline thật | Cache giáo trình/tiến độ theo tài khoản và bé, hàng đợi đồng bộ | Tắt mạng/đóng mở app vẫn giữ tiến độ; kết nối lại không nhân đôi thưởng |
| OCR/AI | Chụp/chọn ảnh → nhận diện → phụ huynh/bé sửa đề → gợi ý từng bước | Có ảnh thật, xử lý ảnh mờ/đề không hỗ trợ, lỗi mạng và hạn mức |
| Quan sát lỗi | Ghi lỗi có ngữ cảnh thao tác và trạng thái sync | Điều tra được lỗi mà không ghi PIN, mật khẩu hoặc ảnh riêng tư vào log |
| Trải nghiệm | Màn hình nhỏ, font lớn, dark mode, âm thanh/đọc đề có tùy chọn | Luồng học chính sử dụng được khi tăng cỡ chữ; giảm chuyển động nếu cần |

Chất lượng giáo trình cần ưu tiên trước số lượng. Seed hiện sinh 30 bài/lớp nhưng nhiều đề/lý thuyết chỉ phụ thuộc khối lớp và thứ tự câu, không theo mục tiêu riêng từng bài. Đáp án đúng cũng thường đặt ở lựa chọn đầu. Cần ma trận lớp → chủ đề → kỹ năng → mức khó, rà soát toán học và trộn thứ tự đáp án. Bổ sung payload thực tế cho đủ 5 dạng tương tác; không suy ra mức bao phủ giáo trình từ con số 1.500 hàng.

Vườn luyện tập hiện hồi 1 tim mỗi câu đúng và ghi log lũy kế mỗi câu; khi bé chỉ thiếu 1 tim có thể kết thúc sau 1 câu. Cần chốt nghiệp vụ “đủ 5 câu để hồi toàn bộ” hay “mỗi câu hồi 1 tim”, rồi thống nhất giao diện, mã và thống kê.

Theo phạm vi cập nhật của người dùng, bán gói học tập cho phụ huynh là chức năng bắt buộc. Cần danh mục gói, đơn hàng, xác minh thanh toán ở server, khôi phục giao dịch và xử lý hết hạn. Cấp quyền thủ công bởi admin chỉ phục vụ hỗ trợ, không thay thế luồng mua gói. Xem kế hoạch chi tiết bổ sung. Không đặt API key AI có quyền bí mật trong ứng dụng.

## 5. Lộ trình triển khai đề xuất

Ước lượng cho nhóm 4 người có thể dành thời gian đều cho dự án; đây là ước lượng lập kế hoạch, chưa phải cam kết. Phần nội dung giáo dục và tích hợp dịch vụ bên ngoài có thể kéo dài. Các giai đoạn phụ thuộc nhau về dữ liệu; không xây báo cáo/AI cá nhân hóa trước khi có phiên học đáng tin cậy.

| Giai đoạn | Thời lượng dự kiến | Công việc | Điều kiện hoàn thành |
|---|---|---|---|
| 1. Ổn định và bảo mật | Tuần 1 | Sửa test/lint, bỏ auth/OTP giả ở chế độ thật, điều hướng theo session, reset state, siết RLS, sửa release INTERNET | Sai mật khẩu không vào app; A không đọc bé của B; đăng xuất không còn state tài khoản cũ; analyze/test đạt |
| 2. Vòng học hoàn chỉnh | Tuần 2 | Hồ sơ CRUD thật, đọc progress/streak, trạng thái phiên học, tính accuracy/XP, thưởng một lần, thời gian học | Tạo bé → học → thoát → mở lại vẫn đúng; không bỏ qua điều kiện/nhận thưởng lặp |
| 3. Dữ liệu sản phẩm | Tuần 3 | Nối sessions/attempts, báo cáo phụ huynh, giao dịch tủ đồ, gói và giới hạn bé hiệu lực | Báo cáo khớp lượt học; mua đồ đồng thời không sai sao; trial/hết hạn khớp UI/backend |
| 4. Nội dung và offline | Tuần 4–5 | Rà giáo trình, quản trị nội dung tối thiểu, cache + hàng đợi, chia nhóm đấu trường thật | Dữ liệu nội dung hợp lệ; offline/reconnect không mất hoặc nhân đôi; nhóm không vượt 30 |
| 5. OCR/AI và phát hành | Tuần 6–7 | Camera/OCR, sửa đề nhận diện, gợi ý an toàn, hạn mức; QA thiết bị và release | Nhận diện được bộ ảnh kiểm thử; lỗi có hướng xử lý; bản release chạy luồng xuyên suốt |

Phân công đề xuất theo trách nhiệm, không thực hiện tạo task hoặc giao việc tự động:

- Thành viên 1: Auth, session, PIN, hồ sơ bé và cách ly state.
- Thành viên 2: Learning engine, phiên học, tiến độ, streak, tim và kiểm định nội dung.
- Thành viên 3: Supabase migrations/RLS/RPC, tủ đồ, đấu trường và quyền lợi Plus.
- Thành viên 4: Cổng phụ huynh, báo cáo, trải nghiệm; phối hợp thiết lập kiểm thử và phát hành.

Nếu cần bản nộp trong 2 tuần: ưu tiên giai đoạn 1–2, thêm báo cáo tối thiểu từ dữ liệu thật; AI hiển thị rõ là demo, Plus cấp thủ công. Dời OCR thật, thanh toán, cá nhân hóa và công cụ quản trị nội dung đầy đủ sang vòng sau.

## 6. Nâng cấp kỹ thuật có mục đích

- Giữ Flutter + Provider + Supabase; chưa cần đổi framework hoặc viết lại ứng dụng.
- Tách state theo Auth, Kid, Curriculum/Progress, LearningSession, Subscription; tách dần tại các luồng đang sửa.
- Dùng repository có thể truyền vào để test độc lập; trả lỗi có kiểu thay vì catch bỏ qua. Không xem “database rỗng” và “không có mạng” là cùng một trạng thái.
- Mọi yêu cầu bất đồng bộ theo hồ sơ cần kiểm tra kid_id/phiên yêu cầu khi trả về, tránh switchKid nhanh khiến kết quả bé trước ghi đè bé sau.
- Tải danh sách bài và câu hỏi theo lô hoặc tải câu hỏi khi mở bài; tránh 30 truy vấn tuần tự khi vào bản đồ. Cache theo grade và phiên bản nội dung.
- Gắn mỗi thao tác hoàn thành/mua/gửi điểm với ID duy nhất; server đảm bảo giao dịch và chống xử lý lặp. Rà quyền ghi trực tiếp các cột sao/XP/inventory.
- Tách cấu hình môi trường và dữ liệu seed demo. Anon/publishable key dùng ở client không tự nó là bí mật; cần bảo vệ bằng RLS và không đưa service-role key vào app.
- Rà quyền EXECUTE, search_path và phạm vi truy cập của các hàm SECURITY DEFINER; thiết kế riêng API leaderboard chỉ trả trường đã duyệt. Không đổi view sang security_invoker một cách máy móc nếu chính sách sở hữu khiến BXH không còn thấy người khác.
- Chưa có cơ sở để công bố app “đạt chuẩn COPPA/GDPR-K” chỉ từ việc dùng nickname và Parent Gate. Cần rà chính sách dữ liệu/quyền riêng tư riêng trước khi công bố; báo cáo này không đánh giá tuân thủ pháp lý.

## 7. Kế hoạch kiểm chứng

| Nhóm | Ca kiểm thử thiết yếu |
|---|---|
| Auth/RLS | Sai mật khẩu, OTP sai/hết hạn, mất mạng, hai gia đình, parent gọi API admin, đổi tài khoản và khôi phục phiên |
| Hồ sơ | Tài khoản 0 bé, tạo đến giới hạn, hai yêu cầu tạo đồng thời, đổi tên/lớp rồi tải lại, xóa thất bại |
| Học | Trả lời sai/đúng, hết tim, không bỏ bước, hoàn tất hai lần, câu trả lời tự luận rỗng/sai, progress sau mở lại |
| Streak | Nhiều bài cùng ngày, ngày kế tiếp, bỏ ngày, trước/sau 21h, giao năm và múi giờ |
| Kinh tế | Hai lần mua đồng thời, mua món đã có, không đủ sao, mất mạng giữa chừng, retry hoàn tất bài/gửi XP |
| Báo cáo/thời gian | Đổi bé, foreground/background, đủ hạn, sang ngày mới, dữ liệu rỗng, tổng thời lượng khớp phiên |
| Offline | Tắt mạng, restart, reconnect, tài khoản khác trên cùng máy, nội dung đổi phiên bản |
| Release | Android release có mạng, fonts offline, PIN, deep link auth, máy nhỏ, font lớn, dark mode |

Thiết lập CI chạy format/analyze/test, kiểm thử RLS và build Android; giữ SQL migrations tái tạo được trên database sạch. Các test hiện tại chủ yếu kiểm tra render, chưa chứng minh nghiệp vụ và tích hợp Cloud hoạt động đúng.

## 8. Kết quả kiểm tra trong phiên đánh giá

- `flutter analyze --no-pub`: 22 issues, gồm 5 warning và 17 info; mã thoát 1. Có import thừa, `_essayDone`/`_miniGameWon` không dùng, cảnh báo BuildContext sau async và API deprecated. README ghi “0 issues” không còn khớp.
- `flutter test --no-pub`: 1 test đạt, 2 test thất bại, mã thoát 1. `main_screen_test.dart` gặp assertion ListTile nằm trong DecoratedBox có nền che hiệu ứng Material; `widget_test.dart` bị `pumpAndSettle timed out`. `onboarding_test.dart` đạt. Chưa xác định nguyên nhân sâu của timeout trong phạm vi đánh giá này. README ghi “All tests passed” không còn khớp.
- Chưa build hoặc chạy trên emulator/thiết bị; chưa xác minh bản release hoặc database Cloud. Các phát hiện nghiệp vụ là đối chiếu mã nguồn, cần kiểm thử hồi quy khi triển khai sửa.
- README và SUPABASE_INTEGRATION_STATUS.md cần cập nhật: giáo trình đã có repository đọc Cloud, còn admin/Plus chưa được mô tả đầy đủ; fallback mẫu chưa phải cache và đồng bộ offline bền vững.

Tham chiếu đối chiếu phân quyền: [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security). Quyền bảng và policy cần được kiểm tra cùng nhau; bật RLS không đủ nếu policy cho phép đọc mọi dòng.
