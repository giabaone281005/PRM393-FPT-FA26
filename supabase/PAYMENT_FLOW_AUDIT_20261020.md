# Kiểm tra luồng thanh toán phụ huynh — 20/10/2026

Phạm vi: ứng dụng Flutter tại `D:/DEMO/PRM391`, các Edge Functions đang ACTIVE và định nghĩa RPC/RLS thực tế trên project phát triển `seoswmcldwwytdrfrrrb`. Đây là kiểm tra luồng và khả năng phục hồi; chưa phải nghiệm thu giao dịch merchant thật.

**Kết luận:** Nhánh VNPay có nền tảng xác thực/chấm nhận thanh toán đúng và vượt qua regression trên database. Toàn bộ luồng thanh toán chưa đủ bằng chứng để coi là sẵn sàng vận hành thật: còn nguy cơ mất đối chiếu khi xóa đơn, MoMo có thể tạo nhiều yêu cầu thu tiền cho cùng một đơn, demo dùng chung sổ giao dịch và chưa có lịch đối soát trong database. Không thay đổi mã ứng dụng, schema, secrets hay deployment trong lần kiểm tra này.

## Luồng thực tế

| Bước | Luồng được kiểm tra | Kết quả/bằng chứng |
|---|---|---|
| Cổng phụ huynh | `ParentGateDialog` cấp token sau xác thực PIN; tạo đơn kiểm tra token ở server | RPC `create_learning_order(p_price,p_key,p_token)` gọi `private.create_parent_order`; thiếu token hợp lệ bị chặn |
| Chọn gói | Gói/giá lấy từ `learning_plans` và `plan_prices`; xác nhận giá, kỳ hạn, không tự gia hạn | Client không gửi số tiền để quyết định giá; server chụp thông tin gói vào snapshot của đơn |
| Tạo/tiếp tục đơn | `CommerceRepository.startPayment` gọi checkout; idempotency key tái sử dụng đơn; server kiểm tra chủ sở hữu và hạn đơn | VNPay regression đạt; RLS ngăn phụ huynh khác đọc đơn |
| Mở thanh toán | VNPay trả URL được ký, app kiểm tra HTTPS/host; MoMo gọi API create; demo mở màn mô phỏng | Chưa thực hiện giao dịch với merchant hoặc xác nhận số tiền bị trừ |
| Chờ xác nhận | Poll `learning_orders.status`, kiểm tra khi app resume, có retry/timeout và giữ đơn trong lịch sử | Widget tests đạt; app không tự đánh dấu paid khi mở URL/nhận deep link |
| Ghi nhận hệ thống | VNPay kiểm tra HMAC, merchant, số tiền, reference rồi gọi RPC service-only | Chữ ký giả bị từ chối; sai số tiền bị từ chối; callback lặp không tạo thêm payment/kỳ quyền |
| Cấp quyền | Settlement cùng giao dịch ghi payment, subscription period, subscription, log rồi đặt đơn paid | Regression xác nhận một payment và một kỳ gói; app tải lại state bằng `refreshSubscription` |
| Đối soát | Nút lịch sử và `commerce-reconcile` chỉ gọi `vnpay-query` | Chưa có nhánh query MoMo; chưa có `pg_cron` trong database |

## Phát hiện cần xử lý

### P1 — Backend vẫn cho xóa đơn đang chờ, mất khả năng nhận callback muộn

Đã xác nhận trên Cloud: `public.discard_unpaid_order(uuid)` và `public.purge_my_unpaid_orders()` vẫn cho role authenticated thực thi. Hàm discard chỉ kiểm tra chủ sở hữu, trạng thái pending/failed/expired và chưa có payment; không yêu cầu PIN và xóa hẳn đơn. Purge có thể xóa đơn pending cũ sau khoảng đệm mặc định 30 phút, hoặc failed sau một phút.

Phép thử có rollback: tạo đơn fixture → khóa cổng bằng `lock_parent()` → discard trả `true` → giả lập callback hợp lệ ở tầng settlement trả mã VNPay `01` (không tìm thấy đơn). Đây là thử RPC database, không gửi callback đến VNPay và không chuyển tiền.

Ảnh hưởng: nếu ngân hàng đã nhận thanh toán nhưng IPN đến chậm sau khi đơn bị xóa, hệ thống không còn đơn để ghi nhận/cấp quyền. UI đã bỏ tự động purge/discard trong lần sửa trước, nhưng API vẫn còn. Không khẳng định app hiện tự gọi xóa khi thoát màn.

Điểm gọi còn tồn tại trong source: `D:/DEMO/PRM391/lib/data/repositories/commerce_repository.dart:200` và `:209`. Định nghĩa xóa quan sát được nằm trên Cloud, không giả định các migration cũ đại diện chính xác cho chúng.

Hướng sửa: giữ đơn/lịch sử đối chiếu, chuyển sang trạng thái kết thúc hoặc ẩn khỏi UI thay vì hard delete; khóa quyền xóa từ client, thiết kế retention chỉ sau khi đã đối soát. Phải dùng migration mới, giữ tương thích và dữ liệu hiện có.

### P1 — MoMo mất idempotency ở phía cổng và bỏ qua giao dịch thứ hai khác mã

Source local `D:/DEMO/PRM391/supabase/functions/momo-checkout/index.ts:57` và function đang chạy `momo-checkout` v3 đều tạo `orderId` bằng ID đơn cộng timestamp, rồi dùng cùng giá trị đó làm `requestId`. Mỗi lần checkout lại tạo một yêu cầu khác ở MoMo; không lưu/reuse attempt của cổng.

Cloud `private.settle_momo_order` trả `OK` ngay khi đơn đã paid/refunded, trước khi đối chiếu mã giao dịch đã ghi. Phép thử rollback gửi hai mã giao dịch thành công khác nhau cho cùng đơn: cả hai trả `OK`, chỉ có một payment được lưu và không có payment cho mã thứ hai. `momo-ipn` v3 chuyển `OK` thành HTTP 204 nên provider coi callback thứ hai đã được xử lý.

Ảnh hưởng suy ra từ hai điểm trên: hai yêu cầu MoMo còn hiệu lực có thể dẫn đến hai lần thu tiền; lần thứ hai không được lưu để xử lý/hoàn tiền. Không thực hiện hoặc khẳng định đã xảy ra hai lần trừ tiền thật.

Hướng sửa: lưu attempt/orderId/requestId của provider, reuse khi retry; phân biệt callback lặp cùng transaction với một transaction khác; ghi nhận khoản trả thêm và đưa vào xử lý đối chiếu/hoàn tiền. MoMo quy định `requestId` là idempotency key: [tài liệu chính thức](https://developers.momo.vn/v3/docs/payment/api/result-handling/idempotency/).

### P1 trước vận hành thật — Demo đang bật, dùng chung payment/kỳ Plus với MoMo

Đã đọc `demo-pay` v4 đang chạy: kiểm tra `DEMO_PAY_ENABLED` trước bước đăng nhập, sau đó action simulate dùng service role gọi `settle_momo_order(...,p_result=0)`. Không có thuộc tính provider/environment của đơn để tách demo khỏi đơn thật. Kết quả được ghi vào payment/source `momo` và cập nhật Plus bằng cùng hàm settlement.

Probe HTTP không đăng nhập tới demo trả 401 “Cần đăng nhập”; theo thứ tự kiểm tra trong source đã đọc, điều này chứng minh function đã đi qua cờ bật demo (nếu tắt sẽ trả 403 trước đó). Không gọi simulate với tài khoản thật hoặc fixture qua endpoint.

Ảnh hưởng: dữ liệu demo không phân biệt được với MoMo thật trong sổ này; nếu dùng chung môi trường merchant, parent có PIN có thể chọn mô phỏng để nhận Plus. Project hiện đã được xác nhận là phát triển, nên đây là giới hạn phải giải quyết trước production, không khẳng định production đang bị khai thác.

Hướng sửa: tắt demo ở môi trường thanh toán thật, tách môi trường/dấu nguồn demo; không dùng giao dịch demo như bằng chứng doanh thu thật. `demo-pay` hiện chỉ tìm thấy trên Cloud, chưa có source tương ứng trong `D:/DEMO/PRM391/supabase/functions/` để kiểm thử và quản lý phiên bản đầy đủ.

### P2 — Thiếu lịch đối soát trong database và thiếu đối soát MoMo

`pg_extension` xác nhận chưa cài `pg_cron`; `to_regclass('cron.job')` là null. Script dự kiến `D:/DEMO/PRM391/supabase/operations/schedule_reconciliation.sql` có lịch gọi `commerce-reconcile`, nhưng lịch đó chưa hiện diện trong database. Chưa xác minh scheduler bên ngoài project, nên không kết luận mọi cơ chế lịch bên ngoài đều không tồn tại.

`commerce-reconcile` v2 chỉ gửi đơn đến `vnpay-query`; nút lịch sử cũng là “Kiểm tra với VNPay” cho mọi đơn pending/failed/expired. Đơn không lưu provider, nên đơn MoMo thiếu luồng kiểm tra trạng thái tương ứng khi IPN không về. App polling chỉ đọc trạng thái đã lưu, không tự hỏi provider.

Ảnh hưởng: xác nhận bị thiếu có thể giữ đơn ở trạng thái chờ cho đến khi có IPN hoặc kiểm tra thủ công đúng kênh; không có bằng chứng job tự chạy định kỳ. Hướng sửa: cấu hình lịch được duyệt và đối soát theo provider/attempt. [Hướng dẫn Supabase scheduling](https://supabase.com/docs/guides/functions/schedule-functions).

### P2 — “Liên kết ví” mới là lưu thông tin do người dùng nhập

Cloud `private.link_wallet` chỉ chuẩn hóa số điện thoại, băm số, kiểm tra trùng và ghi `status='linked'`. Không có OAuth, OTP hoặc token từ MoMo/VNPay để chứng minh sở hữu ví. `start_basic_trial` dùng bản ghi đó làm điều kiện cấp dùng thử 7 ngày.

Vì vậy, không nên giới thiệu đây là ví đã được provider xác thực hoặc phương tiện sẵn sàng thu tiền. Lựa chọn thanh toán thực tế được thực hiện độc lập ở checkout. Cần đổi cách diễn đạt hoặc tích hợp xác thực provider trước khi coi luồng này đã hoàn chỉnh.

## Kiểm thử đã thực hiện trong lần kiểm tra này

- `flutter analyze --no-pub`: không có vấn đề.
- 22 Flutter tests trong payment waiting, cloud repository và commerce models: đạt. Hai widget tests commerce screens bổ sung: đạt. Tổng cộng **24 Flutter tests** trong lượt audit này; một số cloud repository tests bao phủ cả luồng học, không gọi tất cả 24 là test thanh toán.
- `node --test test_backend/handlers.test.mjs test_backend/operations.test.mjs test_backend/vnpay.test.mjs`: **22 đạt**; bộ này có cả payment/refund và AI mocks, không phải 22 giao dịch merchant thật.
- SQL structural validation: **30 file đạt**.
- `commerce_regression.sql` thực thi trên development: đạt và rollback, gồm PIN, RLS, giá từ server, idempotency đơn, số tiền, thanh toán service-only và một kỳ gói.
- Probe database riêng trong phạm vi parent-payment: xác nhận hard delete/callback muộn và hai transaction MoMo cùng đơn như trên; toàn bộ rollback. Bản SQL tái hiện cục bộ: `D:/DEMO/PRM391/build/payment-flow-audit-probe.sql` (artifact được Git bỏ qua, chỉ chạy development/staging).
- HTTP thực tế: checkout không đăng nhập → 401; demo không đăng nhập → 401; IPN chữ ký sai → HTTP 200 với `RspCode=97` (từ chối theo giao thức VNPay); reconcile thiếu job key → 401.
- Sau rollback: **0 user/giá fixture còn lại**. Dữ liệu hiện tại vẫn có **2 đơn paid/2 payment**, tất cả payment ghi provider momo; **0 đơn paid/refunded có số lượng payment khác một**. Vì demo ghi chung momo, các con số này không chứng minh đã chuyển tiền thật.
- `git diff --check`: đạt; các thay đổi ứng dụng có sẵn được giữ nguyên. Lần audit này chỉ bổ sung báo cáo và nhật ký, không sửa luồng thanh toán.

## Giới hạn và việc chưa thực hiện

Không tạo giao dịch merchant thật, không dùng/chỉnh secrets, không áp dụng migration, không deploy, không push. Chưa chạy parent-device → provider → IPN thật → restart → quyền học trên một giao dịch merchant có chứng từ.

Bộ `content_payment_operations.sql` rộng hơn bị automatic approval review từ chối vì tạo role admin/moderator và thực hiện support/refund/content publishing ngoài yêu cầu. Không chạy lại bộ đó; đã thay bằng commerce regression và probe chỉ dùng fixture thanh toán phụ huynh, được chấp nhận. Không cần mở rộng quyền để hoàn thành kiểm tra hiện tại.

Thứ tự xử lý đề xuất trong phạm vi payment: bảo toàn đơn để nhận callback muộn; cô lập demo; lưu attempt và chống thu tiền lặp MoMo; đối soát theo provider và thiết lập lịch; sau đó nghiệm thu một giao dịch sandbox merchant hoàn chỉnh. Chưa đánh dấu luồng thanh toán E2E VERIFIED.
# Cập nhật sau audit

Đã chuẩn bị bản sửa và regression: [FIX_REPORT_20261021.md](D:/DEMO/PRM391/FIX_REPORT_20261021.md). Migration và Edge Functions mới chưa triển khai lên Cloud; các rủi ro backend trong báo cáo này chưa được coi là đã khắc phục trên môi trường đang chạy.
