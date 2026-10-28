# Đầu vào tạo Use Case Diagram — Matlingo

Ngày đối chiếu repository: 28/10/2026.

## 1. Mục đích và phạm vi

Tài liệu này dùng để yêu cầu AI hoặc công cụ UML tạo Use Case Diagram cho hệ thống học tập Matlingo. Có thể gửi toàn bộ file này kèm yêu cầu ở mục 7.

**Hệ thống chỉ có hai actor: User và Admin. Không có actor Phụ huynh, Trẻ em hoặc vai trò parent/kid.** Hồ sơ học tập là dữ liệu do User quản lý, không phải một actor hay một tài khoản trẻ em.

Ranh giới hệ thống mang tên **Matlingo**, bao gồm ứng dụng học tập mobile và chức năng backend quản trị. Dịch vụ xác thực, lưu trữ, AI và chạy code chỉ được mô tả trong ghi chú; không vẽ thêm actor để giữ đúng yêu cầu hai actor.

Phân biệt trạng thái triển khai:

- Mobile đã có các luồng học tập, hồ sơ, tài khoản, sao lưu và cấu hình engine nêu dưới đây.
- Chức năng Admin đã có API backend; dashboard web chưa được tích hợp trong codebase hiện tại. Sơ đồ tổng thể có thể thể hiện các chức năng này nhưng phải ghi chú trạng thái.
- Chat AI và chạy code cần engine bên ngoài được cấu hình và hoạt động.
- Khôi phục mật khẩu có giao diện và luồng xử lý, nhưng mặc định bị tắt bằng cấu hình. Chỉ thể hiện dưới dạng chức năng có điều kiện.

## 2. Actor

| Actor | Vai trò | Phạm vi |
|---|---|---|
| User | Người sử dụng ứng dụng học tập | Tài khoản, hồ sơ học tập, khám phá chủ đề, học tương tác, theo dõi tiến độ, sao lưu, trợ lý AI, thực hành code và cài đặt |
| Admin | Người quản trị hệ thống | Xem tổng quan, quản lý trạng thái tài khoản User, chủ đề, phiên bản hoạt động, bản phát hành và tài nguyên nội dung |

Không vẽ quan hệ kế thừa giữa Admin và User vì chưa có yêu cầu Admin tự động có toàn bộ chức năng học tập của User. Không tạo actor Guest, Supabase, AI Provider, Email Service hoặc Code Engine trong sơ đồ này. Đăng ký và đăng nhập được nối với User, kể cả khi chưa có phiên đăng nhập.

## 3. Use case của User

| ID | Tên use case | Mô tả / điều kiện |
|---|---|---|
| U01 | Đăng ký tài khoản | Tạo tài khoản bằng email và mật khẩu |
| U02 | Xác nhận email | Nhập mã xác nhận khi tài khoản chưa được xác nhận |
| U03 | Gửi lại mã xác nhận | Yêu cầu mã mới khi cần; có thời gian chờ |
| U04 | Đăng nhập | Xác thực bằng email và mật khẩu; bản mobile có cloud yêu cầu đăng nhập trước khi học |
| U05 | Khôi phục mật khẩu | Yêu cầu mã khôi phục, xác minh mã và đặt mật khẩu mới; chỉ khả dụng khi cấu hình cho phép |
| U06 | Đăng xuất | Kết thúc phiên tài khoản và đóng hồ sơ đang mở |
| U07 | Tạo hồ sơ học tập | Đặt tên, chọn sở thích và mục tiêu số phút học mỗi ngày |
| U08 | Chọn hoặc đổi hồ sơ | Mở hồ sơ phù hợp với tài khoản; có thể đóng phiên để đổi hồ sơ |
| U09 | Khám phá chủ đề | Xem danh sách, tìm kiếm, lọc và xem thông tin chủ đề |
| U10 | Học bài tương tác | Bắt đầu chủ đề, thao tác mô hình, kiểm tra bài làm và nhận phản hồi |
| U11 | Xem gợi ý | Mở gợi ý hoặc gợi ý rõ hơn khi đang học |
| U12 | Làm lại hoạt động | Đặt lại hoạt động để thử cách giải khác |
| U13 | Tiếp tục bài đang học | Mở lại tiến độ và bản nháp đã lưu |
| U14 | Hoàn thành chủ đề | Hoàn tất các hoạt động bắt buộc, xem kết quả và XP |
| U15 | Xem tiến độ và lịch sử | Xem thời gian học, hoạt động theo ngày, chủ đề hoàn thành, thành tựu và XP |
| U16 | Sao lưu hồ sơ lên cloud | Tự sao lưu hồ sơ đang mở khi đủ điều kiện; có thông tin trạng thái và thử lại khi lỗi |
| U17 | Khôi phục hồ sơ từ cloud | Chọn bản sao lưu để tạo một hồ sơ riêng trên thiết bị |
| U18 | Đồng bộ kết quả học tập | Gửi phiên học, bản nháp, bài làm và hoàn thành để server xác nhận; chỉ áp dụng nội dung tương thích |
| U19 | Giải quyết xung đột thông tin hồ sơ | Chọn thông tin hồ sơ trên thiết bị hoặc cloud khi phát hiện khác phiên bản |
| U20 | Trò chuyện với trợ lý AI | Gửi câu hỏi và nhận phản hồi từ engine AI đã chọn |
| U21 | Sử dụng bảng vẽ khi chat | Vẽ, hoàn tác hoặc xóa nét; dùng bảng vẽ làm ngữ cảnh cho trợ lý |
| U22 | Thực hành lập trình | Soạn và chạy Python/JavaScript, nhập dữ liệu và xem kết quả/lỗi qua engine chạy code |
| U23 | Quản lý engine học tập | Thêm, sửa, xóa kết nối và chọn engine AI/code độc lập |
| U24 | Tùy chỉnh giao diện | Điều chỉnh giao diện, chữ lớn và giảm chuyển động; lưu lựa chọn trên thiết bị |
| U25 | Xem trợ giúp và giới thiệu | Đọc hướng dẫn sử dụng và thông tin ứng dụng |

### Ràng buộc nghiệp vụ cần ghi chú

- Hồ sơ học tập thuộc phạm vi tài khoản; không cho một tài khoản truy cập hồ sơ đã gắn với tài khoản khác.
- Tiến độ và bản nháp có thể lưu trên thiết bị; thao tác cloud cần phiên xác thực hợp lệ và kết nối.
- XP cá nhân lưu cục bộ và XP server đã xác nhận được hiển thị riêng. Khôi phục backup không tự cấp XP đã xác nhận.
- Hoàn thành chủ đề lần đầu có thể nhận 30 XP; ôn tập và gửi lại cùng thao tác không cấp thưởng trùng. Server xác nhận kết quả trước khi cấp XP đã xác nhận.
- Sao lưu cloud và đồng bộ kết quả học tập là hai luồng khác nhau. Khôi phục tạo hồ sơ riêng, chưa tự hợp nhất tiến độ giữa nhiều thiết bị.
- Catalog mobile có nội dung chưa được phát hành trên server; các bài này vẫn học cục bộ nhưng chưa nhận XP server xác nhận.
- Cấu hình engine có sẵn là tiền điều kiện của chat AI/chạy code; người dùng không phải cấu hình lại engine trong mỗi lần sử dụng.

## 4. Use case của Admin

Các chức năng dưới đây đã có API backend. Không diễn giải thành dashboard web đã hoàn thiện.

| ID | Tên use case | Mô tả / điều kiện |
|---|---|---|
| A01 | Đăng nhập quản trị | Xác thực tài khoản; hệ thống kiểm tra role Admin trước khi cho truy cập chức năng quản trị |
| A02 | Xem tổng quan hệ thống | Đọc dữ liệu tổng quan qua API quản trị |
| A03 | Xem danh sách tài khoản User | Xem dữ liệu tài khoản được API quản trị cung cấp |
| A04 | Khóa hoặc mở tài khoản User | Chuyển trạng thái tài khoản User giữa active và suspended |
| A05 | Quản lý chủ đề | Lưu thông tin chủ đề học tập |
| A06 | Quản lý phiên bản hoạt động | Tạo hoặc cập nhật nội dung ở trạng thái draft; nội dung đã published không được sửa trực tiếp |
| A07 | Tạo bản phát hành nội dung | Tạo release cùng danh sách phiên bản hoạt động và phiên bản app tối thiểu |
| A08 | Xuất bản nội dung | Publish release đáp ứng kiểm tra tương thích nội dung và bộ chấm |
| A09 | Ngừng bản phát hành | Retire release để không nhận phiên học mới trên release đó |
| A10 | Quản lý ảnh nội dung | Tải ảnh lên và gắn tài nguyên hợp lệ vào phiên bản hoạt động còn draft |
| A11 | Xem nhật ký quản trị | Đọc audit qua API quản trị |

Đăng nhập và quyền Admin là tiền điều kiện của A02–A11. Không cần nối tất cả use case quản trị với “Đăng nhập” bằng `include`. Không tự thêm xóa tài khoản, xem mật khẩu, cấp XP thủ công, thanh toán hoặc phân quyền tùy ý.

## 5. Quan hệ UML đề xuất

### Association

- Nối User với các use case U01–U25 thuộc phạm vi của User.
- Nối Admin với các use case A01–A11 thuộc phạm vi của Admin.
- Có thể gom các thao tác chi tiết vào use case tổng quát ở sơ đồ tổng quan; chỉ bung chi tiết ở sơ đồ phân rã.

### Extend — hành vi tùy chọn hoặc có điều kiện

| Use case mở rộng | Use case cơ sở | Điều kiện |
|---|---|---|
| U03 Gửi lại mã xác nhận | U02 Xác nhận email | User cần mã mới và hết thời gian chờ |
| U11 Xem gợi ý | U10 Học bài tương tác | User yêu cầu trợ giúp khi học |
| U12 Làm lại hoạt động | U10 Học bài tương tác | User muốn đặt lại hoạt động |
| U21 Sử dụng bảng vẽ khi chat | U20 Trò chuyện với trợ lý AI | User dùng bảng vẽ để bổ sung ngữ cảnh |
| U19 Giải quyết xung đột thông tin hồ sơ | U18 Đồng bộ kết quả học tập | Server phát hiện xung đột thông tin hồ sơ |

Mũi tên `extend` đi từ use case mở rộng đến use case cơ sở.

### Include — chỉ dùng cho bước bắt buộc được tách riêng

Nếu vẽ sơ đồ học tập chi tiết, có thể tách “Kiểm tra bài làm” từ U10 và dùng `U10 ..> Kiểm tra bài làm : <<include>>` cho luồng học có bước kiểm tra bắt buộc. Nếu vẽ chi tiết khôi phục mật khẩu U05, có thể tách “Xác minh mã khôi phục” và “Đặt mật khẩu mới” thành các bước `include` của luồng khôi phục thành công.

Không bắt buộc sơ đồ phải có `include`. Không dùng `include` hoặc `extend` chỉ để thể hiện thứ tự màn hình. Không nối “Hoàn thành chủ đề” với “Cấp XP đã xác nhận” bằng `include` vô điều kiện, vì còn phụ thuộc lần hoàn thành đầu tiên, nội dung tương thích và kết quả xác nhận server. Đăng nhập, engine đã cấu hình và có mạng thường là tiền điều kiện, không phải các bước luôn thực hiện lại trong từng use case.

## 6. Phần không đưa vào sơ đồ hiện tại

- Actor Phụ huynh, Trẻ em, Teacher, Guest hoặc vai trò ngoài User/Admin.
- Parent Gate, PIN phụ huynh, quản lý con em.
- VNPay, mua Plus/Premium, subscription, hoàn tiền và quà tặng trả phí.
- Stars, Gems, cửa hàng, tủ đồ hoặc mua vật phẩm mascot của phiên bản cũ.
- Voice tutor, thông báo native và dashboard đánh giá mastery như tính năng đã tích hợp hoàn chỉnh.
- Tự hợp nhất tiến độ nhiều thiết bị như chức năng mobile đã hoàn thiện.

## 7. Prompt có thể sao chép

> Hãy tạo UML Use Case Diagram cho hệ thống Matlingo dựa trên tài liệu này.
>
> Yêu cầu bắt buộc:
> 1. Chỉ có đúng hai actor: User và Admin. Tuyệt đối không có Phụ huynh, Trẻ em hoặc actor dịch vụ bên ngoài.
> 2. Đặt các use case trong system boundary tên “Matlingo”; hai actor ở ngoài.
> 3. Viết tên use case bằng tiếng Việt, ngắn gọn, theo dạng động từ + đối tượng.
> 4. Tạo một sơ đồ tổng quan dễ đọc với các nhóm: Tài khoản, Hồ sơ, Học tập, Tiến độ & Cloud, AI & Code, Cài đặt và Quản trị. Ở mức tổng quan, được gom các use case chi tiết vào mục tiêu lớn hơn để tránh quá nhiều đường nối.
> 5. Tạo thêm hai sơ đồ phân rã riêng cho User và Admin nếu sơ đồ tổng quan quá dày. Không bỏ chức năng chi tiết khỏi tài liệu mà không nêu rõ đã gom vào use case nào.
> 6. Dùng association, include và extend đúng ngữ nghĩa UML theo mục 5. Không dùng mũi tên để biểu diễn tuần tự thao tác; không lạm dụng include đăng nhập.
> 7. Ghi chú chức năng Admin hiện có API backend, chưa có dashboard web tích hợp; AI/code cần engine; khôi phục mật khẩu phụ thuộc cấu hình.
> 8. Không bổ sung chức năng thanh toán, parent/kid hoặc chức năng ngoài phạm vi mục 6.
> 9. Trả về mã PlantUML hoàn chỉnh, có @startuml và @enduml cho từng sơ đồ, dùng bố cục left to right direction. Kèm bảng ngắn ánh xạ actor với các use case chính và giải thích các quan hệ include/extend đã dùng.
> 10. Không dùng flowchart thay cho UML Use Case Diagram. Phân biệt rõ chức năng hiện có, chức năng có điều kiện và phần mới có API.

## 8. Nguồn đối chiếu trong workspace

Các đường dẫn bên dưới trỏ đến nguồn hiện tại đã dùng để lập tài liệu; không dùng tài liệu legacy để suy ra tính năng đang hoạt động.

- [README](<D:/Brilliant Clone/brilliant_mobile/repo-history/README.md>)
- [Phạm vi role hiện tại](<D:/Brilliant Clone/brilliant_mobile/repo-history/ROLE_COMMERCE_DEVELOPMENT_PLAN.md>)
- [Trạng thái tích hợp backend](<D:/Brilliant Clone/brilliant_mobile/repo-history/SUPABASE_INTEGRATION_STATUS.md>)
- [API học tập và quản trị](<D:/Brilliant Clone/brilliant_mobile/repo-history/docs/LEARNING_SERVER_API.md>)
- [Kiến trúc engine](<D:/Brilliant Clone/brilliant_mobile/repo-history/docs/ENGINE_ARCHITECTURE.md>)
- [Luồng học và hồ sơ](<D:/Brilliant Clone/brilliant_mobile/repo-history/lib/journey_app.dart>)
- [Tạo/chọn hồ sơ](<D:/Brilliant Clone/brilliant_mobile/repo-history/lib/entry_flow.dart>)
- [Tài khoản và sao lưu](<D:/Brilliant Clone/brilliant_mobile/repo-history/lib/features/account/cloud_account_page.dart>)
- [Menu và cài đặt](<D:/Brilliant Clone/brilliant_mobile/repo-history/lib/settings_menu.dart>)
