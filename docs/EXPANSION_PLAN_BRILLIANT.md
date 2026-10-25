# Kế hoạch mở rộng Nảy theo định hướng Brilliant

Ngày khảo sát: 23/10/2026. Trạng thái: **chỉ lập kế hoạch, chưa triển khai**.

## 1. Định hướng

Ưu tiên biến 24 thí nghiệm hiện tại thành một sản phẩm học dài hạn: người học biết bắt đầu ở đâu, hiểu vì sao mình sai, gặp lại kiến thức đúng lúc và nhận ra mình tiến bộ ở kỹ năng nào.

Giữ các quyết định đã chốt:

- Flutter, hồ sơ trên thiết bị và học offline là nền tảng.
- Không multiple choice, không trang lý thuyết bắt buộc; giải thích ngắn trong lúc thao tác hoặc sau khám phá.
- Một hệ font, bảng màu Brilliant và tỷ lệ nút gọn cho toàn bộ màn hình.
- Sáng tạo ở cơ chế học, hệ quả của thao tác và cách diễn đạt ý tưởng. Không yêu cầu mọi bài phải dùng một engine đồ họa mới.
- Nội dung và minh họa mới do ứng dụng thiết kế; không lấy nguyên bộ bài của Brilliant.

## 2. Những gì xác minh được từ Brilliant

Đây là thông tin từ trang trợ giúp công khai, không phải kiểm chứng toàn bộ trải nghiệm sau đăng nhập:

| Tham chiếu | Điểm đã xác minh | Ý nghĩa đối với Nảy |
|---|---|---|
| [Learning Paths](https://brilliant.org/help/features/what-are-learning-paths/) | Có thứ tự học gợi ý và các điểm thực hành kiểm tra; đang đổi tên course/level/lesson thành topic/unit/concept | Cần phân cấp chương trình, không chỉ thêm thẻ chủ đề |
| [Koji](https://brilliant.org/help/features/how-does-koji-work/) | Trợ giảng dùng trạng thái tương tác để hướng dẫn và có thể đánh dấu/thao tác trên môi trường học | Ưu tiên gợi ý có ngữ cảnh trước khi cân nhắc chat AI |
| [Tìm bài bằng câu hỏi](https://brilliant.org/help/features/ask-koji-a-math-question-and-find-the-right-lesson/) | Người dùng web có thể diễn đạt nhu cầu để được dẫn tới bài liên quan | Có thể mở rộng tìm kiếm theo kỹ năng và cách diễn đạt đời thường |
| [Product Features](https://brilliant.org/help/features/) | Liệt kê XP, streak, leagues, widget, reset tiến độ và dashboard phụ huynh | Đánh giá riêng tính năng hỗ trợ học và tính năng xã hội |
| [Brilliant Basics](https://brilliant.org/help/using-brilliant/) | Brilliant yêu cầu internet và đồng bộ tiến độ giữa thiết bị | Nảy chủ động giữ offline; không sao chép ràng buộc kết nối |
| [Parent dashboard](https://brilliant.org/help/features/parent-progress-dashboards-on-brilliant/) | Tổng hợp hoạt động, thực hành, chủ đề và kỹ năng | Báo cáo tiến bộ cần có ý nghĩa hơn tổng XP |

Trang danh mục `/courses/` chỉ trả tiêu đề trong lần đọc công khai này. Không suy đoán số lượng bài hiện tại hoặc kết luận đã khảo sát từng tương tác của Brilliant. Các hạng mục dưới đây là đề xuất cho Nảy, không phải tuyên bố Brilliant có mọi chức năng tương tự.

## 3. Khoảng thiếu trong ứng dụng hiện tại

Đối chiếu README, catalog, lesson runner, mô hình thí nghiệm và nơi lưu phiên:

| Hạng mục | Đang có | Khoảng thiếu / hệ quả | Ưu tiên |
|---|---|---|---|
| Chương trình học | 8 chủ đề × 3 thí nghiệm | Chưa có chương, cấp độ, kỹ năng tiên quyết hay bản đồ lộ trình | P0 |
| Độ dài bài | Runner có tiến độ và nhãn cố định 3 bước | Không phù hợp bài ngắn/dài hoặc checkpoint khác nhau | P0 |
| Nội dung | 24 cơ chế riêng | Mỗi cơ chế chủ yếu có trạng thái khởi tạo cố định; thiếu biến thể và thử thách vận dụng | P0 |
| Đánh giá | Validator đúng/sai | Chưa mô tả sai ở đâu, vì sao sai hoặc cách tiếp theo phù hợp | P0 |
| Gợi ý | Một hint dạng chuỗi cho mỗi bài | Chưa có các nấc gợi ý hoặc đánh dấu trực tiếp mô hình | P1 |
| Cá nhân hóa | Sở thích, nhịp học, bài đang làm | Gợi ý bài mới chủ yếu theo sở thích/chưa hoàn thành; chưa dựa trên kỹ năng | P1 |
| Ôn tập | Có thể học lại | Chưa có lịch ôn, hàng đợi bài cần củng cố và đánh giá lại qua biến thể mới | P1 |
| Tiến độ | Hoàn thành, XP, lịch sử | XP hiện tính số chủ đề hoàn thành × 30, tối đa 240 với catalog này; chưa có mức vững kỹ năng | P0 |
| Lịch sử | Lưu tối đa 100 lượt hoàn thành | Khi mở rộng cần tách lịch sử gần đây khỏi dữ liệu tổng hợp dài hạn | P0 |
| Tìm kiếm | Có ô tìm và bộ lọc tất cả/chưa học/đang học | Cần tìm không dấu, theo kỹ năng, cấp độ và thời lượng; không xây lại từ đầu | P1 |
| Hồ sơ | Tạo/mở/đổi, nhịp học hiển thị | Chưa có sửa hồ sơ, thay mục tiêu, quản lý bản sao lưu và khôi phục | P0 |
| Chất lượng mobile | Có test 320px, cỡ chữ lớn, reduced motion và APK | Chưa đo trên điện thoại thật, chưa kiểm chứng iOS, vòng đời native và hiệu năng dài phiên | P0 |
| Sản xuất nội dung | Catalog và giao diện viết trực tiếp trong Dart | Khó mở rộng, kiểm duyệt và nâng phiên bản bài mà không mất bản nháp | P1 |

P0 = nền móng cần xử lý trước khi mở rộng mạnh. P1 = hoàn thiện giá trị học tập sau nền móng. P2 = mở rộng sau khi thử nghiệm cho thấy có nhu cầu.

## 4. Các task đề xuất và thứ tự thực hiện

### Giai đoạn A — Nền móng chương trình và dữ liệu

**A1. Thiết kế cấu trúc nội dung.** Đề xuất phân cấp `Lộ trình → Chủ đề → Chương → Bài khám phá → Hoạt động`. Gắn kỹ năng, mức khó, thời lượng ước tính, kiến thức tiên quyết và phiên bản nội dung. Phân biệt bài khám phá, thực hành và checkpoint.

**A2. Thiết kế dữ liệu tiến độ.** Tách hoàn thành nội dung, mức vững kỹ năng, lịch sử luyện tập và XP. Dùng ID ổn định; quy định nhận XP lần đầu/ôn tập/checkpoint để tránh cộng trùng khi bấm lại hoặc mở lại app. XP không đại diện cho năng lực.

**A3. Bỏ ràng buộc ba bước trong thiết kế mới.** Cho phép số hoạt động tùy bài; progress, nhãn hoàn thành và bản nháp cùng đọc từ nội dung. Khi nâng dữ liệu phải bảo toàn hồ sơ, XP đã nhận và các phiên hợp lệ của bản v3.

**A4. Sao lưu offline.** Lập luồng xuất/nhập hồ sơ; xem trước tên hồ sơ và ngày sao lưu, kiểm tra phiên bản, chọn tạo hồ sơ mới hoặc thay thế có xác nhận. Dữ liệu nhập lỗi không làm hỏng hồ sơ đang dùng. Chọn công nghệ lưu trữ sau khi ước lượng số bản ghi; cân nhắc SQLite cho lịch ôn và lịch sử truy vấn, không chuyển chỉ vì có thư viện mới.

**Điều kiện nghiệm thu:** chuyển dữ liệu v3 thành công; không lẫn hồ sơ; không mất bản nháp khi lỗi ghi; không giới hạn 3 hoạt động; tổng tiến độ không phụ thuộc danh sách 8 chủ đề cố định.

### Giai đoạn B — Một lộ trình mẫu đủ sâu

**B1. Làm sâu một lộ trình trước.** Đề xuất “Số và tỉ lệ”: 3 chương × 4 bài, gồm lượng bằng nhau, phân số tương đương, tỉ lệ và vận dụng. Đây là phạm vi đề xuất để kiểm chứng chất lượng, không phải cam kết số bài đã có.

**B2. Thiết kế nhịp học linh hoạt.** Một bài có thể đi từ khám phá → tạo lời giải → đổi điều kiện → vận dụng; bài khác bắt đầu từ dự đoán bằng thao tác hoặc sửa một mô hình sai. Không ép mọi bài dùng cùng thứ tự và số màn.

**B3. Tạo checkpoint tương tác.** Kết hợp nhiều kỹ năng bằng nhiệm vụ mới, giảm trợ giúp ban đầu; nếu gặp khó thì chỉ ra bài nền nên quay lại. Cho phép khám phá tự do, không khóa cứng mọi nội dung theo điểm số.

**B4. Tiêu chuẩn nghiệm thu nội dung.** Mỗi bài cần mục tiêu học, hiểu lầm thường gặp, lời giải hợp lệ, tình huống biên, thao tác thay thế cho kéo/vuốt và quan sát nào chứng minh người học hiểu. Không coi thay màu, đổi số hoặc tăng tốc là một cơ chế mới.

**Điều kiện nghiệm thu:** người học giải được một biến thể mới sau khi học; bài không thể qua chỉ bằng chạm ngẫu nhiên vài lần; thao tác và lời giải được kiểm tra về toán học.

### Giai đoạn C — Phản hồi và trợ giảng offline

**C1. Đánh giá có giải thích.** Mở rộng từ đúng/sai sang kết quả gồm trạng thái, lỗi nhận diện được, vùng liên quan và gợi ý kế tiếp. Không tự nhận biết lỗi khi mô hình chưa có đủ bằng chứng.

**C2. Gợi ý ba nấc.** Nấc đầu nhắc quan sát; nấc tiếp đánh dấu một thành phần; nấc cuối minh họa một bước trên bản xem thử. Người học vẫn hoàn thành hành động cuối. Không tự sửa và ghi đè bài đang làm.

**C3. Phản hồi ngay tại vật thể.** Ví dụ: đòn bẩy cho thấy hai mômen; robot đánh dấu lệnh đầu tiên đi vào vật cản; phân số cho thấy các phần chưa bằng nhau. Chuyển động có mục đích giảng giải và tôn trọng giảm chuyển động.

**C4. Trợ giảng tùy chọn.** Bản đầu là hệ quy tắc offline, gọi đúng là “gợi ý theo mô hình”. AI hội thoại chỉ là hạng mục riêng nếu sau này người dùng muốn kết nối; cần đánh giá chi phí, dữ liệu và khả năng kiểm chứng. Không hứa AI offline tương đương Koji.

**Phụ thuộc:** A1 và bài mẫu B. **Nghiệm thu:** gợi ý khớp trạng thái hiện tại, không tiết lộ toàn bộ lời giải, không đổi tiến độ chỉ do animation.

### Giai đoạn D — Ôn tập và cá nhân hóa

**D1. Bản đồ kỹ năng.** Hiển thị “mới gặp / đang luyện / đã vận dụng / nên ôn”. Dựa trên nhiều lần thực hành và biến thể, không dựa riêng thời gian, tốc độ hay số lần dùng hint.

**D2. Hàng đợi ôn tập.** Lên lịch cục bộ theo lần thử, hỗ trợ đã dùng và kết quả ở biến thể mới. Khoảng ôn ban đầu là giả thuyết sản phẩm cần thử nghiệm; luôn cho người học tự chọn bài.

**D3. Trang Hôm nay có lý do gợi ý.** Đưa ra một việc chính: tiếp tục bài, ôn kỹ năng hoặc khám phá mới; giải thích bằng câu ngắn như “Ôn tỉ lệ vì bạn đã gặp khó ở hai lần gần nhất”. Mục tiêu phút/ngày là hướng dẫn, không ép ngắt phiên.

**D4. Khám phá nâng cấp.** Tìm không dấu; tag kỹ năng; lọc cấp độ/thời lượng; lưu bài yêu thích. Tìm bằng câu tự nhiên có thể bắt đầu bằng từ đồng nghĩa offline, hiển thị kết quả gần đúng rõ ràng.

**Phụ thuộc:** A2, B và C. **Nghiệm thu:** khuyến nghị truy được nguyên nhân, lịch ôn còn sau khởi động lại, không lặp vô hạn cùng một mẫu bài.

### Giai đoạn E — Mở rộng chủ đề và cơ chế sáng tạo

Chỉ mở rộng sau khi lộ trình mẫu B–D đạt yêu cầu. Các hướng nội dung sau là đề xuất mới cho Nảy:

| Hướng | Tương tác dự kiến | Mục tiêu học |
|---|---|---|
| Đại số và hàm số | Kéo điểm để tạo quy luật; biến đổi đồ thị bằng tay cầm; sửa “máy hàm” sai | Quan hệ biến và hệ số |
| Hình học không gian | Gập lưới thành khối; cắt mặt phẳng; xoay vật để tìm hình chiếu | Tư duy không gian |
| Dữ liệu và thống kê | Chải chọn điểm dữ liệu; đổi mẫu để quan sát độ ổn định; cân ảnh hưởng của ngoại lệ | Mẫu, phân phối, trung bình |
| Thuật toán | Đặt breakpoint trực quan; chạy từng lệnh; xây đường đi có chi phí | Trạng thái, điều kiện và tối ưu |
| Khoa học | Dựng đường ánh sáng qua thấu kính; tạo sóng; thay vật liệu dẫn nhiệt | Nhân quả và mô hình |
| Xác suất | Tự thiết kế phép thử; chạy nhiều lượt; so sánh tần suất và dự đoán | Thực nghiệm và xác suất |
| AI cơ bản | Đặt ranh giới phân loại; điều chỉnh trọng số rồi quan sát lỗi; kiểm tra trên điểm mới | Khái quát hóa và dữ liệu |

Giữ Flutter Canvas/CustomPainter cho 2D. Chỉ thử Flame khi cần vòng lặp mô phỏng/game; chỉ thử engine 3D khi nội dung không thể giải thích tốt bằng 2D. Mỗi thử nghiệm công nghệ phải chứng minh lợi ích trên thiết bị đích trước khi trở thành phụ thuộc chung.

Cần “bộ công cụ tác giả”: dữ liệu nội dung có schema, registry cơ chế, seed biến thể tái hiện được, validator, preview bài, bộ lời giải chuẩn và checklist nội dung. Seed không bảo đảm bài đúng: bộ sinh phải kiểm tra nghiệm tồn tại, độ khó và trường hợp biên. Tái sử dụng kỹ thuật nhưng đổi nhiệm vụ nhận thức, không nhân bản hàng trăm màn kéo-thả giống nhau.

### Giai đoạn F — Thói quen, báo cáo và sẵn sàng phát hành

**F1. Hồ sơ/cài đặt:** đổi tên, sở thích và nhịp học; tùy chọn âm thanh/rung/chuyển động; sao lưu; xem dung lượng và quản lý dữ liệu.

**F2. Báo cáo cá nhân:** kỹ năng đã luyện, bài nên ôn, hoạt động theo tuần và ví dụ vận dụng. Có thể thêm chế độ xem cho người đồng hành trên cùng thiết bị; không tự tạo liên kết phụ huynh hoặc gửi báo cáo ra ngoài.

**F3. Nhịp học nhẹ nhàng:** lịch hoạt động và mục tiêu tuần. Nhắc học cục bộ là tùy chọn, xin quyền khi bật. Không đưa streak phạt, leagues hay bảng xếp hạng online vào phạm vi offline hiện tại.

**F4. Kiểm thử thiết bị:** Android cấu hình thấp/trung bình, iOS trên macOS/Xcode, tablet, cỡ chữ lớn, trình đọc màn hình, mất focus/chuyển nền, force-close và khôi phục. Đo độ trễ kéo, frame time và pin ở mô phỏng nặng; không cam kết 60/120 FPS chỉ dựa vào tên framework.

**F5. Chuẩn bị phát hành:** build release có ký, kiểm tra app size và font, màn hỗ trợ/quyền riêng tư, quản lý phiên bản nội dung, kiểm tra bản nâng cấp từ APK đang dùng. Điều kiện phát hành được chốt sau kiểm tra thiết bị, không lấy web preview thay thế.

## 5. Các màn cần bổ sung hoặc mở rộng

Luồng đề xuất: Vào hồ sơ → Hôm nay → Bản đồ lộ trình → Chủ đề/chương → Bài tương tác → Checkpoint → Kết quả theo kỹ năng → Ôn tập hoặc bài tiếp theo.

- Hôm nay: giữ một CTA chính, thêm lý do gợi ý và hàng ôn ngắn.
- Khám phá: giữ tìm kiếm hiện có, thêm bộ lọc và truy cập lộ trình.
- Lộ trình/chương: mục tiêu, thứ tự gợi ý, tiến độ và điểm quay lại.
- Bài học: số bước linh hoạt, gợi ý theo mô hình, thao tác thay thế, lưu và thoát.
- Kết quả: phát hiện mới, kỹ năng cần ôn và một việc tiếp theo.
- Hành trình: lịch sử + bản đồ kỹ năng + luyện tập; không chỉ phần trăm hoàn thành.
- Hồ sơ: chỉnh sửa, tùy chọn trải nghiệm, xuất/nhập sao lưu.

Tất cả tiếp tục dùng chung token, font, palette, nút theo nội dung và hệ chuyển động. Dữ liệu mô phỏng có thể dùng màu phân biệt khi có ý nghĩa học tập; không tạo palette riêng cho từng trang.

## 6. Thứ tự ưu tiên để bắt đầu sau này

1. A: mô hình chương trình, tiến độ và bảo toàn dữ liệu.
2. B: một lộ trình mẫu có chiều sâu, thay vì tăng đồng loạt tám chủ đề.
3. C: phản hồi lỗi và gợi ý theo trạng thái.
4. D: biến thể, ôn tập và khuyến nghị theo kỹ năng.
5. E: mở rộng nội dung qua công cụ tác giả đã kiểm chứng.
6. F: hoàn thiện hồ sơ, báo cáo và phát hành; kiểm tra mobile/accessibility diễn ra xuyên suốt A–E.

Không đưa vào đợt đầu: backend tài khoản, cloud sync, AI online, thanh toán/subscription, quảng cáo, bảng xếp hạng và mạng xã hội. Đây là các quyết định sản phẩm riêng, không phải điều kiện để có trải nghiệm học tốt như định hướng Brilliant.

## 7. Cách biết kế hoạch có hiệu quả

Theo dõi cục bộ, không tự gửi analytics: khả năng giải biến thể mới; lỗi còn lặp sau ôn; tỷ lệ tiếp tục đúng bản nháp; lỗi lưu/khôi phục; mức sử dụng thao tác thay thế; hiệu năng đo trên thiết bị. Không tối ưu chỉ theo thời gian dùng app, số lần chạm hoặc XP.

Chưa có ước lượng thời gian đáng tin cho toàn bộ phạm vi vì nội dung mới cần thiết kế và thử với người học. Sau A và một bài mẫu B, mới ước lượng các đợt còn lại theo dữ liệu thực tế.

## 8. Phạm vi của lượt khảo sát này

Chỉ tạo tài liệu kế hoạch này. Không sửa mã ứng dụng, dữ liệu người dùng, cấu hình, dependency hay bản build; không chạy triển khai hoặc tạo task thực thi. Các kết quả 37 kiểm thử trong tài liệu trước là mốc đã có từ lượt triển khai trước, không phải kiểm thử mới của lượt lập kế hoạch.
