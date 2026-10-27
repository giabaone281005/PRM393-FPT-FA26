# API học tập trên Supabase

Cập nhật 26/10/2026. Backend được bổ sung vào codebase hiện tại, không thay UI.

## Trạng thái và ranh giới tích hợp

- Project: `seoswmcldwwytdrfrrrb`, Singapore.
- Edge Function `learning-api` đã triển khai. Base URL:
  `https://seoswmcldwwytdrfrrrb.supabase.co/functions/v1/learning-api`.
- Catalog `frontend-baseline-2026-10-26` đã published: 11 topics, 53 hoạt động,
  30 cơ chế chấm. Chỉ các phiên bản nội dung khớp evaluator đã triển khai được publish.
- Hai bucket private: `learning-assets`, `user-avatars`; ảnh PNG/JPEG/WebP tối đa 2 MiB.
- Các API Auth và `save_mobile_backup` giữ nguyên.
- **Mobile 1.3.1+5 đã nối canonical writes** bằng local journal: profile, session,
  draft, attempt và completion. Mã request/snapshot được lưu bền vững trước khi gửi;
  response mất thì gửi lại đúng request, đổi tài khoản không chuyển payload sang owner mới.
  App vẫn dùng catalog đóng gói, kiểm tra tương thích trước khi mở session server.
  XP được server xác nhận hiển thị riêng; không tự nhập backup thành XP verified.
  Mobile chưa tự merge incremental change feed giữa hai thiết bị; backup/restore
  vẫn là luồng chuyển máy, kèm fork session/draft/attempt ID cho nhánh mới.
- AI chat và code playground tiếp tục sử dụng Engine Registry; API này không cung
  cấp một LLM hoặc Docker/compiler service. Các provider/sandbox cần cấu hình riêng.
- CLI đã đăng nhập ngày 26/10/2026 và đã xóa đủ 12 Edge Functions legacy.
  Danh sách live chỉ còn `learning-api` (v4 sau sửa conflict). Không triển khai lại các stub.
- Hosted email OTP template/subject/sender Matlingo đã áp dụng và xác minh; chưa test mailbox thật.

## Xác thực và phân quyền

Tất cả route nghiệp vụ cần `Authorization: Bearer <access_token>` của Supabase Auth.
POST dùng `Content-Type: application/json`. Không đưa service-role key vào Flutter/web.
`OPTIONS` trả 204 không cần JWT.

Function dùng `verify_jwt=false` để tương thích các loại signing key của Auth,
nhưng handler bắt buộc kiểm tra token bằng `/auth/v1/user`, sau đó đọc role/status
hiện hành từ DB. Không tin JWT tự decode hoặc `user_metadata` để cấp quyền.
Mọi mutation kiểm tra lại quyền/owner trong DB. User bị suspended không thể sync/ghi.

Các RPC public là SECURITY INVOKER, chỉ được cấp EXECUTE cho đúng infrastructure
role; code ghi nhạy cảm nằm trong private với search_path cố định. User không có
quyền ghi trực tiếp attempt/completion/XP hoặc gọi RPC commit evaluation của server.

## Các route

| Method / path | Quyền | Chức năng |
|---|---|---|
| GET `/catalog?app_version=1.3.0` | user | Catalog published mới nhất tương thích app |
| POST `/mutate` | user | Hồ sơ, session, draft, telemetry, hoàn thành |
| POST `/attempts` | user | Server tự chấm trạng thái bài làm và ghi attempt |
| GET `/sync?revision=0&index=-1&limit=100` | user | Change log riêng của owner, phân trang |
| GET `/progress?profile_id=<uuid>` | user | XP verified, thống kê topic/attempt |
| POST `/assets` | user/admin | Upload avatar hoặc ảnh nội dung theo role |
| GET `/assets/<uuid>` | owner hoặc người được đọc nội dung | Signed URL sống 300 giây |
| GET `/admin?section=overview&offset=0&limit=50` | admin | Tổng quan, accounts, topics, activities, releases, audit |
| POST `/admin` | admin | Quản lý nội dung draft, publish/retire, khóa/mở user |
| POST `/admin/assets` | admin | Gắn ảnh ready vào một activity version còn draft |

REST đọc bảng hiện có vẫn chịu RLS; ví dụ `/rest/v1/accounts?select=*` chỉ trả account
được phép xem. Đọc hồ sơ/sessions/attempts qua REST không cấp quyền mutation.

## Mutation và idempotency

Envelope cho `/mutate`, `/admin`:

```json
{
  "operation_id": "UUID tạo một lần và lưu bền vững trước khi gửi",
  "operation_type": "profile.create",
  "payload": {}
}
```

UUID ví dụ ở trên là mô tả, khi gọi phải dùng UUID hợp lệ. Mỗi lần sửa nội dung
yêu cầu tạo operation_id mới; retry sau timeout dùng đúng ID và payload cũ.
Cùng ID/cùng payload trả receipt cũ; cùng ID/khác payload bị từ chối.
Mutation học được tuần tự hóa theo owner, ghi receipt/change log trong cùng transaction.
Không gửi một transaction học lớn; mỗi request là một thao tác độc lập.

| operation_type | payload |
|---|---|
| `account.update` | `display_name`, `locale`, `timezone` (IANA timezone hợp lệ) |
| `profile.create` | `id` UUID, `name`, `daily_minutes` 1–120, `interest_topic_ids` array, `onboarded` optional |
| `profile.update` | Như create, thêm `expected_revision` |
| `profile.delete` | `id`, `expected_revision`; soft delete, không xóa lịch sử vật lý |
| `session.start` | `id` UUID, `profile_id`, `release_id`, `topic_id`, `device_id` optional, `started_at` ISO optional |
| `draft.save` | `id` UUID, `session_id`, `activity_id`, `expected_revision`, `snapshot` object |
| `event.record` | `session_id`, `activity_id`, `event_type`, `active_ms` hoặc `hint_level` |
| `session.complete` | `session_id` |
| `session.abandon` | `session_id` |

Profile tối đa 100/account, tên 1–60 ký tự; interests không trùng và phải tồn tại.
Draft mới dùng expected_revision=0, cập nhật dùng revision vừa nhận. Conflict trả 409;
giữ bản local, lấy thay đổi server rồi tạo nhánh UUID khác hoặc quyết định hợp nhất.
API không âm thầm ghi đè snapshot cũ. Profile tombstone làm vô hiệu toàn bộ cây dữ
liệu của profile trên thiết bị nhận sync; máy cũ không thể mở session ghi lại profile đó.

Session chỉ mở trên release published, topic đúng manifest và profile còn active.
Release retired không nhận session mới; phiên đang học giữ release/version đã pin.
`started_at` chấp nhận trong 90 ngày qua, tối đa 5 phút tương lai.

Event `active_time` có active_ms 0–60000/lần; `hint_opened` có hint_level 0–3.
Thời gian nhận/ngày địa phương tính từ server và timezone account. Telemetry không
chứng minh người học thật sự hoạt động và không bao giờ là điều kiện cấp XP.

Receipt:

```json
{
  "operation_id": "<uuid>",
  "revision": "12",
  "result": {
    "session": {},
    "draft": null,
    "attempt": null,
    "completion": null,
    "xp_awarded": 0
  }
}
```

Các thao tác account/profile trả row ở `result`. Các trường revision trong API
mutation/sync được serialize thành chuỗi để tránh mất độ chính xác ở web.

## Chấm bài, completion và XP

POST `/attempts`:

```json
{
  "operation_id": "<uuid>",
  "payload": {
    "session_id": "<uuid>",
    "activity_id": "logic-balance",
    "content_version": 1,
    "state": {"blocks": 4},
    "hint_level": 0
  }
}
```

Không gửi is_correct, evaluator output, owner hoặc XP. Handler lấy owner từ Auth và
tự đánh giá state bằng JS biên dịch từ các evaluator Dart hiện có. DB đối chiếu
session/topic/release/content/config/evaluator hash trước khi ghi. State tối đa
64 KiB; handler chặn độ sâu >8, array >128, giá trị số bất thường và string quá dài.

`evaluation_status=verified` nghĩa server đã chấm, không có nghĩa trả lời đúng;
đọc `is_correct` để hiển thị đúng/sai. `feedback_key` giữ contract evaluator mobile,
với evaluator mặc định có thể vẫn là `try-again`; UI phải ưu tiên `is_correct` khi
hiển thị thành công. Không hiển thị một feedback mặc định trái với kết quả này.

Completion yêu cầu ít nhất một required activity và đủ attempt đúng cho mọi required
activity của session/release đó. Completion và ledger được commit nguyên tử.
Thưởng 30 XP cho lần đầu hoàn thành topic/profile, không thưởng lại theo session
hoặc release mới. Unique reward_key bảo vệ cả retry và thao tác đồng thời.

RPC `record_learning_attempt` chỉ cho service_role gọi từ Edge; client không được
tự truyền kết quả chấm vào RPC. Backend không chạy mã Dart/JS do người dùng gửi.

## Đồng bộ nhiều thiết bị

Bootstrap canonical bắt đầu revision=0,index=-1. Lấy high_water từ trang đầu và giữ
nguyên khi phân trang:

```text
GET /sync?revision=0&index=-1&limit=100
GET /sync?revision=<next_revision>&index=<next_index>&high_water=<high_water>&limit=100
```

Lưu payload và cursor nguyên tử trên thiết bị. Nếu has_more=true tiếp tục; khi false,
lần poll tiếp theo giữ next_revision/next_index và bỏ high_water để nhận commit mới.
Một revision có thể chứa nhiều entity; không bỏ qua index. Tối đa 200 rows/trang và
khoảng 1 MiB payload/trang. Change log và receipts hiện chưa bị prune; không tự xóa
chúng cho đến khi có retention/bootstrap replacement rõ ràng.

Các bảng canonical đang rỗng trước rollout, nên mọi dữ liệu mới đều có change log.
Backup v3 cũ là dữ liệu riêng; API này chưa tự chuyển backup thành canonical records.

## Quản trị và tài nguyên

Admin mutations: `account.status` (`id`,status=active/suspended; chỉ target user),
`topic.save` (metadata), `activity.save` (draft version), `release.create` (UUID,
version_label,min_app_version,activities manifest), `release.publish`, `release.retire`.
Chỉ hai role user/admin; không có API tự nâng quyền. Bootstrap admin là thao tác vận hành.

Một evaluator version active gắn với implementation hash bất biến. Thay validator,
config, nội dung câu hỏi hoặc content_version cần release/evaluator tương ứng; không
đổi mã rồi ghi đè hash v1. Các version đang published không sửa trực tiếp.

POST `/assets` nhận JSON `mime_type`, `base64`, optional `source_url`,`license`,`attribution`.
Nguồn ngoài phải HTTPS và có license. Header magic bytes phải khớp MIME. Server tính
SHA-256, đặt path owner/hash.extension, upload không overwrite và xác nhận metadata
Storage trước khi đánh dấu ready. Tối đa 10 ảnh/user hoặc 10000 ảnh/admin; ảnh cùng
hash/owner trả asset cũ. Hiện chỉ nhận ảnh, chưa có pipeline GLB/model hay quét ảnh.

POST `/admin/assets` nhận `{operation_id,payload:{activity_id,content_version,slot,asset_id,required}}`.
Chỉ gắn learning asset ready vào draft. Cả published attachment cũng bất biến.
Ảnh của user không thể được gắn vào manifest nội dung.

GET `/assets/<uuid>` kiểm tra metadata bằng JWT và RLS trước khi ký URL 300 giây.
URL đã ký có hiệu lực đến khi hết hạn; không coi suspend là thu hồi tức thì các link đã cấp.
Upload thành công nhưng register thất bại có thể để lại object chưa tham chiếu; cần
GC vận hành có grace period/đối chiếu trước khi production lớn, không xóa object theo
timeout vì transaction register có thể đã commit.

## Lỗi

```json
{"error":{"code":"activities_incomplete","message":"Bạn cần hoàn thành các hoạt động bắt buộc trước khi kết thúc bài."}}
```

401: thiếu/sai/hết hạn JWT. 403: account unavailable hoặc sai quyền/owner.
409: revision/uniqueness conflict hoặc nội dung published bất biến.
400: payload/cursor không hợp lệ, bài chưa xong hoặc release chưa sẵn sàng.
413: request quá lớn. 422: activity chưa có evaluator hỗ trợ. 503: backend chưa xử lý được.
Không trả SQL diagnostics, token, key hoặc provider secrets cho client.

## Kiểm thử và vận hành

- `flutter test --no-pub` xuất parity corpus vào build/server_evaluator_cases.json.
- `node supabase/tests/evaluator_parity.mjs`: 729 ca so sánh VM/JS, đủ 53 hoạt động.
- `deno check supabase/functions/learning-api/index.ts`.
- `deno test supabase/tests/learning_handler_test.ts`: Auth, authority, size limits,
  error messages, sync cursor, upload metadata và kiểm tra RLS trước khi ký URL.
- `supabase/tests/learning_api_smoke.sql`: chạy SQL trên project đích; toàn bộ fixture
  Auth/application/Storage rollback. Kiểm tra ownership, retry, conflict, XP, pagination,
  suspension, tombstone, admin, asset registration và chặn quyền client/anon.
- `python tools/check_learning_http.py`: HTTP thật cho thiếu/sai JWT và OPTIONS.
- `python tools/build_server_evaluator.py` tái biên dịch bằng Flutter/Dart đã pin;
  giữ URI import tương đối trong entrypoint để không đổi thứ tự minifier vô cớ.
- Migration mới được tạo bằng CLI rồi đặt sau các file legacy tương lai theo AGENTS.md.
  Remote tool ghi timestamp riêng: reconcile theo tên/nội dung, không db push/reset mù.
- Không chạy schema_reset.sql. Không cần service key trong config mobile.

Lượt phone readiness bổ sung `integration_test/phone_readiness_test.dart`: đăng nhập
qua UI trên Android emulator, học đủ một topic, nhận 30 XP server, retry không thưởng
trùng, xung đột metadata và lựa chọn người dùng, local reopen, backup/restore, logout.
Mạng Auth/REST/Edge và SharedPreferences platform là thật; bàn phím được điều khiển
bởi test input để tránh IME ghi đè thao tác tự động. Fixture dùng account riêng và
namespace preferences riêng; đã dọn backend fixture sau khi kiểm thử.
Điện thoại vật lý/hộp thư thật của người dùng, AI provider, sandbox và iOS chưa được
xác nhận bằng các kiểm thử này. Xem `PHONE_READINESS.md`.

Public RPC business conflicts dùng PT409. Không dùng 40001 cho optimistic revision
conflict vì PostgREST có thể retry vòng lặp thay vì trả lỗi; wrapper mới giữ nguyên
CAS/RLS, trả HTTP 409. [Lý do và hướng xử lý chính thức](https://supabase.com/kb/troubleshooting/high-cpu-and-infinite-transaction-retries-when-using-custom-error-codes-in-rpc-functions).

Security advisors còn cảnh báo Auth leaked-password protection đang tắt từ trước;
thiết lập cần quyền Auth config. [Hướng dẫn Supabase](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).
Private tables bật RLS không có client policy là deny-all có chủ đích; unused indexes
trên backend mới chưa có traffic không phải lý do tự xóa index.
