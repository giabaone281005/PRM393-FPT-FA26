# Kế hoạch mở rộng chiều sâu bài học và chức năng từ khảo sát Brilliant

Ngày: 25/10/2026. Kế hoạch ban đầu và cập nhật triển khai cho Matlingo Flutter hiện tại.

### Cập nhật triển khai nền tảng

- Đã thêm hợp đồng `SkillSpec`, `ChapterSpec`, `LessonSpec`, `ActivitySpec` trong `lib/curriculum.dart`, với ID ổn định và metadata cho ba hoạt động phân số hiện có.
- `ExperimentSpec` có phiên bản nội dung/cơ chế, kỹ năng và `EvaluationResult`; validator cũ tiếp tục chạy qua adapter. Bài `math-paint` đã dùng evaluator kiểm tra lát hợp lệ và mục tiêu 3/8. Chưa suy ra lỗi khái niệm từ số lát tô sai.
- Thêm kiểm thử tham chiếu metadata, toàn bộ 256 tập con của 8 lát, trạng thái sai kiểu và adapter cũ trong `test/curriculum_test.dart`. Định dạng mã đã chạy; Flutter test bị chặn do không có quyền ghi `C:/flutter/bin/cache/lockfile`, chưa xác nhận test đạt.
- Chưa hoàn tất mốc A hoặc pilot: metadata chưa có màn chương/bài riêng; chưa có seed, checkpoint, gợi ý ba mức, bản ghi kỹ năng hay migration storage. Bộ ba hoạt động trên vẫn chạy trong luồng chủ đề hiện tại. JSON round-trip trong test chỉ kiểm tra dữ liệu evaluator, không thay thế kiểm thử lưu/khôi phục tích hợp.

## 1. Căn cứ và mức độ xác minh

Áp dụng skill `C:/Users/kzrok/.agents/skills/reverse-engineer-anything/SKILL.md`.

- Khảo sát mới: REA `capture_browser_scenario`, Chrome headless với hồ sơ tạm, mở https://brilliant.org/, chờ 2 giây và thu DOM/URL. Evidence: `ev_5e865ffcbcde63822d714c04c8461c9f7cc758c2ce836408affb6dbf26c702cc`; DOM SHA-256: `2776b732748863aab8c315f492987070f50a69d09212b0472fa997b15629f3e0`. Hai bước hoàn thành; browser được đóng (`terminated-owned-process`). Bản tóm tắt có trích nội dung: [lesson-depth-rea-summary.json](evidence/lesson-depth-rea-summary.json).
- Trang công khai giới thiệu hướng dẫn bằng hình, kế hoạch thích ứng, đánh giá kỹ năng, luyện tập có mục tiêu và báo cáo tiến độ. Đây là nội dung được quan sát trên trang giới thiệu; chưa chứng minh cơ chế nội bộ hoặc chất lượng của AI.
- Bằng chứng REA trước: [MATLINGO_REA_UPGRADE.md](MATLINGO_REA_UPGRADE.md), [REA_ANALYSIS.md](REA_ANALYSIS.md) và các bundle trong `docs/evidence/`. Đây là tham chiếu lịch sử, không coi là capture hiện tại.
- Chưa khảo sát phiên học sau đăng nhập, bài trả phí, luồng ảnh/voice hoặc đồng bộ đa thiết bị. Không suy diễn endpoint, mô hình dữ liệu hay thuật toán Brilliant từ trang chủ.

Nguồn đối chiếu: [Brilliant](https://brilliant.org/). Toàn bộ cấu trúc chương trình, ngưỡng đánh giá và lịch ôn dưới đây là đề xuất riêng cho Matlingo.

## 2. Hiện trạng làm mốc

Nguồn chính là mã, vì README và báo cáo cũ còn mô tả 8 chủ đề/24 thí nghiệm.

| Thành phần | Đã có | Khoảng trống cần xử lý |
|---|---|---|
| Nội dung | `learning_catalog.dart` có 10 chủ đề, gồm Đại số và Thuật toán hiệu quả; catalog mở rộng có bước Vận dụng/Thử thách | Chưa có hệ kỹ năng và quan hệ tiên quyết riêng |
| Bài tương tác | `ExperimentSpec`: cơ chế, cấu hình, trạng thái đầu, validator, gợi ý và giải thích | Validator chủ yếu trả bool; thiếu mã lỗi hiểu sai và bằng chứng từng kỹ năng |
| Lộ trình | 3 tuyến, mở chủ đề trực tiếp | Tiến độ còn theo chủ đề; thiếu chương, checkpoint và nhánh bù nền tảng |
| Ôn tập | Gợi ý theo lịch sử, số lần thử/gợi ý hoặc qua 7 ngày UTC | Dùng lại bài; chưa có biến thể và lịch ôn từng kỹ năng |
| Lưu trữ | Hồ sơ offline, bản nháp, lịch sử và XP; storage v3 | Lịch sử giới hạn 100 bản ghi; không dùng riêng lịch sử này làm nguồn tổng hợp năng lực lâu dài |
| Trợ giúp | Gợi ý theo trạng thái cho một số cơ chế; box chat chờ backend | Chưa có hội thoại AI, nhận ảnh, voice hay đồng bộ |

## 3. Thiết kế chiều sâu

Tổ chức theo Chủ đề → Chương → Bài → Hoạt động; gắn kỹ năng vào từng hoạt động. Một bài 5–10 phút, có thể tách thành hai phiên khi thử nghiệm cho thấy quá dài.

Chuỗi hoạt động: khám phá tự do → dự đoán bằng thao tác → kiểm chứng → vận dụng với dữ kiện mới → tìm phản ví dụ/sửa lỗi → checkpoint độc lập. Giữ hướng tương tác hiện tại; không bắt buộc thêm trắc nghiệm, ô đáp án số hay trang lý thuyết dài.

Mỗi bài có: mục tiêu quan sát được, kỹ năng tiên quyết, 2–3 hiểu sai phổ biến, ít nhất 3 biến thể hợp lệ, phản hồi theo lỗi, gợi ý ba mức và điều kiện hoàn thành. Chấp nhận nhiều lời giải nếu chúng thỏa ràng buộc; giải thích nêu quan hệ/bất biến thay vì chỉ nhắc đáp án.

### Bản đồ mở rộng cho 10 chủ đề

| Chủ đề | Chuỗi phát triển | Thử thách chứng minh hiểu |
|---|---|---|
| Logic | Cân bằng → bảo toàn → suy luận điều kiện → phản ví dụ | Tạo trường hợp làm sai một quy tắc tưởng đúng |
| Những phần bằng nhau | Phần của toàn thể → tương đương → so sánh → tỉ lệ | Biểu diễn cùng tỉ lệ với tổng khác và giải thích bằng ghép hình |
| Chuyển động | Vị trí/thời gian → tốc độ → đồ thị → ràng buộc | Hai hành trình cùng quãng đường nhưng khác thời gian nghỉ |
| Dữ liệu | Đọc biểu đồ → phân nhóm → trung bình/trung vị → ngoại lệ | Hai tập cùng trung bình nhưng phân bố khác nhau |
| Hình học | Diện tích/chu vi → đối xứng → biến đổi → đa điều kiện | Dựng hình đạt diện tích và chu vi cùng lúc |
| Lập trình | Chuỗi lệnh → vòng lặp → điều kiện → kiểm thử | Chương trình chạy được trên nhiều bản đồ chưa gặp |
| Mạch điện | Mạch kín → nối tiếp/song song → cổng logic → mô hình | Dựng mạch thỏa bảng trạng thái; không suy diễn vật lý vượt khả năng mô phỏng |
| Xác suất | Không gian mẫu → tỉ lệ → thực nghiệm → điều kiện | So sánh dự đoán với mô phỏng và nhận ra dao động mẫu |
| Đại số | Cân bằng hai vế → cô lập ẩn → quan hệ → hệ ràng buộc | Giải cùng cấu trúc bằng mô hình mới, gồm nghiệm không nguyên khi engine hỗ trợ |
| Thuật toán hiệu quả | Gỡ lỗi → tính đúng → chi phí → đánh đổi | Tìm đầu vào phản ví dụ và cải tiến lời giải trong ngân sách |

Ưu tiên pilot Phân số → Đại số và Lập trình → Thuật toán, tận dụng cơ chế hiện có. Dữ liệu → Xác suất là đợt tiếp; Hình học/Logic/Chuyển động/Mạch mở rộng sau khi pipeline nội dung ổn định.

## 4. Chức năng theo ưu tiên

| Mức | Chức năng | Kết quả mong muốn |
|---|---|---|
| P0 | Hệ kỹ năng, metadata và version nội dung | Theo dõi hiểu từng khái niệm; bài mới không phá bản nháp cũ |
| P0 | Biến thể xác định bằng seed | Ôn bằng dữ kiện mới; khôi phục đúng đề sau mở lại |
| P0 | Phản hồi hiểu sai và gợi ý phân tầng | Phân biệt sai mục tiêu, sai ràng buộc và thao tác chưa đủ |
| P0 | Checkpoint và trạng thái kỹ năng | Phân biệt hoàn thành với tự giải được |
| P1 | Chẩn đoán ngắn đầu tuyến, có thể bỏ qua | Đề xuất điểm bắt đầu và giải thích lý do |
| P1 | Ôn cách quãng và hàng đợi thực hành | Chọn kỹ năng cần gặp lại; không cộng trùng XP bài cũ |
| P1 | Bản đồ chương và dashboard kỹ năng | Thấy đã học, cần ôn và bước tiếp theo |
| P1 | Xuất/nhập bản sao lưu cục bộ | Giảm mất tiến độ và hỗ trợ migration |
| P2 | Trợ giảng hội thoại có ngữ cảnh canvas | Hỏi dẫn dắt dựa trên trạng thái và lỗi, có fallback offline |
| P2 | Tài khoản/đồng bộ; ảnh và voice | Chỉ triển khai khi có đặc tả backend, chi phí và cách xử lý dữ liệu |

Không đưa chat lên trước việc hoàn thiện nội dung và đánh giá. Mọi thao tác AI lên canvas cần đi qua tập lệnh cho phép, kiểm tra hợp lệ và có hoàn tác; khóa API nằm ở backend.

## 5. Quy tắc đánh giá và ôn ban đầu

- Trạng thái kỹ năng: chưa gặp → đang luyện → tự giải được → cần ôn. XP và thời gian học không thay thế đánh giá hiểu.
- Đề xuất ban đầu: hai checkpoint độc lập với seed khác nhau, trong đó có một bài chuyển ngữ cảnh, mới ghi “tự giải được”. Đã dùng gợi ý thì vẫn hoàn thành bài, nhưng cần một lượt độc lập khác cho kỹ năng tương ứng.
- Không coi chậm, thử nhiều hoặc dùng hỗ trợ tiếp cận là bằng chứng tự động của hiểu sai. Chỉ ghi lỗi khái niệm khi evaluator nhận diện được.
- Lịch ôn thử nghiệm: sau 1, 3, 7, 14 ngày; điều chỉnh theo kết quả độc lập. Đây là heuristic cần đánh giá với người học.
- Ưu tiên: bản nháp → ôn đến hạn → bù tiên quyết → bài mới. Luôn có lý do và cho người học tự chọn bài.
- Ghi `dueAt` UTC; hiển thị ngày theo múi giờ thiết bị. Thống nhất cách tính khi đổi múi giờ và đồng hồ bị chỉnh.

## 6. Kiến trúc và dữ liệu dự kiến

- Thêm `SkillSpec`, `ChapterSpec`, `LessonSpec`, `ActivitySpec` với ID ổn định, `skillIds`, `prerequisiteIds`, `difficulty`, `contentVersion`, `mechanismVersion` và chính sách chấm.
- Bổ sung `EvaluationResult {isCorrect, misconceptionCodes, satisfiedConstraints, feedbackKey}`. Giữ adapter từ validator bool hiện có trong giai đoạn chuyển tiếp; không đổi hàng loạt cơ chế cùng lúc.
- Biến thể tách config bất biến khỏi trạng thái thao tác. Lưu seed, phiên bản generator và config cụ thể để nâng cấp app vẫn mở đúng đề cũ. Generator phải chứng minh có nghiệm trong miền hỗ trợ.
- Tạo `AttemptRecord` gồm profile, activity, variant, kỹ năng, kết quả, mức gợi ý, lỗi khái niệm và thời điểm; không lưu mọi pointer event. Lưu tổng hợp kỹ năng riêng để việc cắt lịch sử 100 dòng không xóa bằng chứng năng lực.
- Tách trạng thái hoàn thành bài, năng lực kỹ năng và sổ thưởng XP. Quy tắc XP mới cần đặc tả riêng; migration giữ nguyên XP đã nhận.
- Migration v3 → phiên bản mới: sao lưu snapshot, chuyển dữ liệu theo ID, kiểm tra trước khi commit; giữ trạng thái cũ để phục hồi nếu ghi lỗi. Dữ liệu cũ chỉ chứng minh đã hoàn thành, không tự nâng thành “tự giải được”.
- Chuyển trách nhiệm từng phần khỏi `journey_app.dart`; thêm dịch vụ evaluator, variant và review độc lập. Chỉ quyết định thay SharedPreferences sau khi đo kích thước/độ trễ snapshot và nhu cầu truy vấn.

## 7. Lộ trình giao việc và nghiệm thu

Ước lượng sơ bộ cho một lập trình viên cùng người duyệt nội dung; cần hiệu chỉnh sau pilot. Mỗi mốc phụ thuộc nghiệm thu mốc trước.

| Mốc | Thời lượng | Phạm vi và điều kiện xong |
|---|---|---|
| A — Đặc tả và khảo sát | 3–5 ngày | Kiểm kê catalog thực, ma trận kỹ năng, 6 hồ sơ bài mẫu; nếu có phiên Brilliant do người dùng cung cấp thì thu trọn một bài/ôn/checkpoint và ghi rõ các giới hạn |
| B — Nền tảng | 1–2 tuần | Metadata, evaluator tương thích cũ, seed và migration; đọc lại dữ liệu v3, XP không đổi, lỗi ghi không mất dữ liệu |
| C — Pilot chiều sâu | 2–3 tuần | 2 chương × 3 bài × 3 biến thể = 18 biến thể cho toàn pilot; mỗi bài có checkpoint và phản hồi hiểu sai |
| D — Ôn và tiến độ | 1–2 tuần | Chẩn đoán có bỏ qua, dashboard, ôn cách quãng, lý do đề xuất; đúng hồ sơ/múi giờ và không cộng trùng XP |
| E — Mở rộng nội dung | 3–5 tuần | Áp dụng mẫu đã duyệt cho 10 chủ đề theo từng đợt; nghiệm thu từng chương, không đặt quota số bài thay chất lượng |
| F — AI/backend | Ước lượng riêng | Chốt bộ ngữ cảnh, quyền canvas, chi phí, đồng bộ và đánh giá phản hồi trước khi phát hành |

Pilot minh họa: chương Phân số gồm “cùng phần khác hình”, “giữ tỉ lệ khi đổi tổng”, “phối trộn có ràng buộc”; chương Lập trình gồm “vòng lặp thay chuỗi lệnh”, “sửa lỗi bằng phản ví dụ”, “tối ưu trong ngân sách”.

## 8. Kiểm chứng và tiêu chí phát hành

- Kiểm thử evaluator với lời giải đúng đa dạng, trạng thái gần đúng nhưng vi phạm ràng buộc, dữ liệu sai kiểu và trạng thái khôi phục.
- Kiểm tra generator theo miền đầu vào; miền hữu hạn nhỏ thì vét cạn, miền lớn thì kiểm tra thuộc tính cùng tập seed cố định. Cùng seed/version tạo cùng cấu hình, trạng thái đầu chưa hoàn thành, bài có nghiệm.
- Kiểm tra lưu/khôi phục đúng activity/variant; migration từ dữ liệu thật đã ẩn danh; cô lập hồ sơ; ghi lỗi; hoàn thành lặp; tổng hợp kỹ năng còn đúng sau cắt lịch sử.
- Chạy analyze và các test liên quan, sau đó regression hiện có khi tích hợp. REA scenario kiểm chứng đường đi: mở bài → thử sai → gợi ý → rời app → tiếp tục → checkpoint → ôn biến thể.
- QA ở 320/390px, chữ lớn, giảm chuyển động và thao tác thay thế cho kéo. Kiểm tra Android thật trước phát hành; Flutter web không chứng minh trải nghiệm native.
- Đánh giá pilot với người học: khả năng giải biến thể mới sau một khoảng nghỉ, lỗi khái niệm tái diễn và mức phụ thuộc gợi ý. Chưa đặt mục tiêu phần trăm cải thiện khi chưa có baseline.

Bước triển khai đầu tiên được đề xuất: hoàn tất mốc A và làm trọn một bài Phân số theo hợp đồng mới để xác nhận kiến trúc trước khi nhân rộng.
