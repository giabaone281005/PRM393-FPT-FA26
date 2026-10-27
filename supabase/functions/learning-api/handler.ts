import {
  ApiError,
  cors,
  errorResponse,
  json,
  readJson,
} from "../_shared/http.ts";

type Options = {
  url: string;
  publishableKey: string;
  serviceKey: string;
  implementationHash: string;
  evaluate: (input: string) => string;
  fetch?: typeof fetch;
};
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Keep potentially adversarial state bounded before entering compiled validators.
function validState(value: unknown, depth = 0): boolean {
  if (depth > 8) return false;
  if (value === null || typeof value === "boolean") return true;
  if (typeof value === "number") {
    return Number.isFinite(value) && Math.abs(value) <= 1000000;
  }
  if (typeof value === "string") return value.length <= 1024;
  if (Array.isArray(value)) {
    return value.length <= 128 && value.every((x) => validState(x, depth + 1));
  }
  if (typeof value === "object") {
    return Object.keys(value).length <= 64 &&
      Object.values(value).every((x) => validState(x, depth + 1));
  }
  return false;
}

export function createHandler(options: Options) {
  const requestFetch = options.fetch ?? fetch;
  async function upstream(
    path: string,
    token: string,
    body?: unknown,
    server = false,
  ): Promise<unknown> {
    const response = await requestFetch(`${options.url}${path}`, {
      method: body === undefined ? "GET" : "POST",
      headers: {
        apikey: server ? options.serviceKey : options.publishableKey,
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: body === undefined ? undefined : JSON.stringify(body),
      signal: AbortSignal.timeout(15000),
      redirect: "error",
    });
    const data = await response.json();
    if (!response.ok) {
      const code = data?.code;
      if (
        path === "/auth/v1/user" && [400, 401, 403].includes(response.status)
      ) {
        if (code === "user_banned") {
          throw new ApiError(
            403,
            "account_unavailable",
            "Tài khoản hiện không thể sử dụng dịch vụ. Vui lòng liên hệ hỗ trợ.",
          );
        }
        throw new ApiError(
          401,
          "authentication_required",
          "Phiên đăng nhập không hợp lệ hoặc đã hết hạn. Hãy đăng nhập lại.",
        );
      }
      if (
        code === "P0001" && [
          "Published activity versions are immutable",
          "Published release manifests are immutable",
          "Published release metadata is immutable",
        ].includes(data?.message)
      ) {
        throw new ApiError(
          409,
          "published_content_immutable",
          "Nội dung đã phát hành không thể sửa trực tiếp. Hãy tạo phiên bản mới.",
        );
      }
      if (response.status === 401) {
        throw new ApiError(
          401,
          "authentication_required",
          "Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.",
        );
      }
      if (code === "42501" || response.status === 403) {
        throw new ApiError(
          403,
          "access_denied",
          "Bạn không có quyền thực hiện thao tác này hoặc dữ liệu không còn khả dụng.",
        );
      }
      if (code === "PT409" || code === "40001" || code === "23505") {
        throw new ApiError(
          409,
          "revision_conflict",
          "Dữ liệu đã thay đổi. Hãy đồng bộ rồi thử lại; bản trên thiết bị vẫn được giữ.",
        );
      }
      if (
        ["22023", "22P02", "22007", "23502", "23503", "23514", "22003"]
          .includes(code)
      ) {
        // Stable business codes, never raw SQL/internal errors or secrets.
        const known: Record<string, [string, string]> = {
          "Required activities are not complete": [
            "activities_incomplete",
            "Bạn cần hoàn thành các hoạt động bắt buộc trước khi kết thúc bài.",
          ],
          "Published lesson unavailable": [
            "lesson_unavailable",
            "Bài học này chưa được phát hành hoặc không còn mở phiên mới.",
          ],
          "Session already closed": [
            "session_closed",
            "Phiên học này đã kết thúc. Hãy mở phiên học mới.",
          ],
          "Operation ID reused with different payload": [
            "operation_mismatch",
            "Yêu cầu gửi lại có dữ liệu khác. Hãy tạo mã yêu cầu mới.",
          ],
          "Invalid or expired sync cursor": [
            "sync_cursor_invalid",
            "Mốc đồng bộ không hợp lệ. Hãy đồng bộ lại từ đầu.",
          ],
          "Unsupported lesson version or invalid state": [
            "unsupported_lesson_version",
            "Phiên bản bài học này chưa được bộ chấm hỗ trợ. Hãy cập nhật nội dung hoặc ứng dụng.",
          ],
          "Cannot publish without verified backend evaluator coverage": [
            "release_not_ready",
            "Bản phát hành còn thiếu nội dung, bộ chấm hoặc tài nguyên hợp lệ.",
          ],
          "Profile limit reached": [
            "profile_limit",
            "Tài khoản đã đạt giới hạn hồ sơ học.",
          ],
          "Asset limit reached": [
            "asset_limit",
            "Bạn đã đạt giới hạn ảnh được lưu.",
          ],
        };
        const reason = known[data?.message] ??
          [
            "invalid_payload",
            "Dữ liệu chưa phù hợp với bài học. Hãy kiểm tra rồi thử lại.",
          ];
        throw new ApiError(400, reason[0], reason[1]);
      }
      throw new ApiError(
        503,
        "server_unavailable",
        "Máy chủ chưa xử lý được yêu cầu. Vui lòng thử lại.",
      );
    }
    return data;
  }
  const rpc = (name: string, token: string, body: unknown, server = false) =>
    upstream(`/rest/v1/rpc/${name}`, token, body, server);

  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: cors });
    }
    try {
      if (!options.url || !options.publishableKey || !options.serviceKey) {
        throw new Error("Missing server configuration");
      }
      const authorization = request.headers.get("authorization") ?? "";
      if (!authorization.startsWith("Bearer ") || authorization.length > 8192) {
        throw new ApiError(
          401,
          "authentication_required",
          "Hãy đăng nhập để tiếp tục.",
        );
      }
      const token = authorization.slice(7);
      // Validate with Auth, not by decoding unverified JWT claims.
      const user = await upstream("/auth/v1/user", token) as { id: string };
      if (!uuid.test(user.id)) {
        throw new ApiError(
          401,
          "authentication_required",
          "Hãy đăng nhập lại để tiếp tục.",
        );
      }
      const access = await rpc("get_my_access", token, {}) as {
        role: string;
        status: string;
      }[];
      if (access.length !== 1 || access[0].status !== "active") {
        throw new ApiError(
          403,
          "account_unavailable",
          "Tài khoản hiện không thể sử dụng dịch vụ. Vui lòng liên hệ hỗ trợ.",
        );
      }
      const url = new URL(request.url);
      const path = url.pathname.replace(/^.*\/learning-api\/?/, "").replace(
        /\/$/,
        "",
      );
      if (request.method === "POST" && path === "assets") {
        const data = await readJson(request, 2900000);
        if (
          typeof data.base64 !== "string" || data.base64.length > 2796204 ||
          typeof data.mime_type !== "string" ||
          !["image/png", "image/jpeg", "image/webp"].includes(data.mime_type) ||
          (data.source_url !== undefined &&
            (typeof data.source_url !== "string" ||
              !/^https:\/\//.test(data.source_url) ||
              typeof data.license !== "string" || !data.license.trim())) ||
          [data.source_url, data.license, data.attribution].some((x) =>
            x !== undefined && (typeof x !== "string" || x.length > 2000)
          )
        ) {
          throw new ApiError(
            400,
            "invalid_asset",
            "Ảnh cần dùng PNG, JPEG hoặc WebP, tối đa 2 MB; ảnh bên ngoài cần thông tin bản quyền.",
          );
        }
        let bytes: Uint8Array<ArrayBuffer>;
        try {
          bytes = Uint8Array.from(atob(data.base64), (x) => x.charCodeAt(0));
        } catch {
          throw new ApiError(400, "invalid_asset", "Dữ liệu ảnh chưa hợp lệ.");
        }
        const isPng = [137, 80, 78, 71, 13, 10, 26, 10].every((x, i) =>
          bytes[i] === x
        );
        const isJpg = bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255;
        const isWebp = new TextDecoder().decode(bytes.slice(0, 4)) === "RIFF" &&
          new TextDecoder().decode(bytes.slice(8, 12)) === "WEBP";
        if (
          bytes.length < 12 || bytes.length > 2097152 ||
          !(data.mime_type === "image/png" && isPng ||
            data.mime_type === "image/jpeg" && isJpg ||
            data.mime_type === "image/webp" && isWebp)
        ) {
          throw new ApiError(
            400,
            "invalid_asset",
            "Định dạng hoặc kích thước ảnh chưa hợp lệ.",
          );
        }
        const hash = Array.from(
          new Uint8Array(await crypto.subtle.digest("SHA-256", bytes)),
          (x) => x.toString(16).padStart(2, "0"),
        ).join("");
        const bucket = access[0].role === "admin"
          ? "learning-assets"
          : "user-avatars";
        const extension = data.mime_type === "image/png"
          ? "png"
          : data.mime_type === "image/jpeg"
          ? "jpg"
          : "webp";
        const objectPath = `${user.id}/${hash}.${extension}`;
        const duplicate = await upstream(
          `/rest/v1/assets?select=*&created_by=eq.${user.id}&sha256=eq.${hash}&status=eq.ready&limit=1`,
          token,
        ) as unknown[];
        if (duplicate.length === 1) return json(duplicate[0]);
        const existing = await upstream(
          `/rest/v1/assets?select=id&created_by=eq.${user.id}&status=eq.ready&limit=${
            access[0].role === "admin" ? 10000 : 10
          }`,
          token,
        ) as unknown[];
        if (existing.length >= (access[0].role === "admin" ? 10000 : 10)) {
          throw new ApiError(
            400,
            "asset_limit",
            "Bạn đã đạt giới hạn ảnh được lưu.",
          );
        }
        const uploaded = await requestFetch(
          `${options.url}/storage/v1/object/${bucket}/${objectPath}`,
          {
            method: "POST",
            headers: {
              apikey: options.serviceKey,
              Authorization: `Bearer ${options.serviceKey}`,
              "Content-Type": data.mime_type,
              "x-upsert": "false",
            },
            body: bytes,
            signal: AbortSignal.timeout(30000),
            redirect: "error",
          },
        );
        const uploadResult = await uploaded.json();
        if (
          !uploaded.ok &&
          !["409", "Duplicate"].includes(
            String(uploadResult.statusCode ?? uploadResult.error),
          )
        ) {
          throw new ApiError(
            503,
            "asset_upload_failed",
            "Chưa tải được ảnh. Vui lòng thử lại.",
          );
        }
        return json(
          await rpc("register_learning_asset", options.serviceKey, {
            actor: user.id,
            asset_data: {
              bucket_id: bucket,
              object_path: objectPath,
              mime_type: data.mime_type,
              sha256: hash,
              byte_size: bytes.length,
              source_url: data.source_url,
              license: data.license,
              attribution: data.attribution,
            },
          }, true),
        );
      }
      if (request.method === "GET" && path.startsWith("assets/")) {
        const assetId = path.slice(7);
        if (!uuid.test(assetId)) {
          throw new ApiError(400, "invalid_asset", "Mã ảnh chưa hợp lệ.");
        }
        // RLS on the user's JWT decides access before using privileged signing.
        const assets = await upstream(
          `/rest/v1/assets?select=bucket_id,object_path,status&id=eq.${assetId}`,
          token,
        ) as { bucket_id: string; object_path: string; status: string }[];
        if (assets.length !== 1 || assets[0].status !== "ready") {
          throw new ApiError(
            404,
            "asset_unavailable",
            "Ảnh không còn khả dụng hoặc bạn chưa có quyền xem.",
          );
        }
        const asset = assets[0];
        const signed = await upstream(
          `/storage/v1/object/sign/${encodeURIComponent(asset.bucket_id)}/${
            asset.object_path.split("/").map(encodeURIComponent).join("/")
          }`,
          options.serviceKey,
          { expiresIn: 300 },
          true,
        ) as { signedURL: string };
        if (!signed.signedURL?.startsWith("/object/sign/")) {
          throw new Error("Unexpected storage URL");
        }
        return json({
          url: `${options.url}/storage/v1${signed.signedURL}`,
          expires_in: 300,
        });
      }
      if (request.method === "GET" && path === "catalog") {
        return json(
          await rpc("learning_catalog", token, {
            app_version: url.searchParams.get("app_version") ?? "1.3.0",
          }),
        );
      }
      if (request.method === "GET" && path === "sync") {
        return json(
          await rpc("learning_changes", token, {
            after_revision: url.searchParams.get("revision") ?? "0",
            after_index: Number(url.searchParams.get("index") ?? "-1"),
            until_revision: url.searchParams.get("high_water"),
            page_size: Number(url.searchParams.get("limit") ?? "100"),
          }),
        );
      }
      if (request.method === "GET" && path === "progress") {
        const profileId = url.searchParams.get("profile_id") ?? "";
        if (!uuid.test(profileId)) {
          throw new ApiError(
            400,
            "invalid_profile",
            "Hãy chọn hồ sơ học hợp lệ.",
          );
        }
        return json(
          await rpc("learning_progress", token, { profile_id: profileId }),
        );
      }
      if (request.method === "GET" && path === "admin") {
        return json(
          await rpc("admin_learning_read", token, {
            section: url.searchParams.get("section") ?? "overview",
            page_offset: Number(url.searchParams.get("offset") ?? "0"),
            page_size: Number(url.searchParams.get("limit") ?? "50"),
          }),
        );
      }
      if (
        request.method === "POST" &&
        ["mutate", "attempts", "admin", "admin/assets"].includes(path)
      ) {
        const body = await readJson(request);
        if (
          typeof body.operation_id !== "string" ||
          !uuid.test(body.operation_id) ||
          !body.payload || typeof body.payload !== "object" ||
          Array.isArray(body.payload)
        ) {
          throw new ApiError(
            400,
            "invalid_operation",
            "Thiếu mã yêu cầu hoặc dữ liệu hợp lệ.",
          );
        }
        const mutation = {
          operation_id: body.operation_id,
          operation_type: body.operation_type,
          payload: body.payload,
        };
        if (path === "admin/assets") {
          return json(
            await rpc("admin_link_learning_asset", token, {
              operation_id: body.operation_id,
              payload: body.payload,
            }),
          );
        }
        if (path === "admin") {
          return json(await rpc("admin_learning_mutate", token, mutation));
        }
        if (access[0].role !== "user") {
          throw new ApiError(
            403,
            "access_denied",
            "Chức năng học dành cho tài khoản người học.",
          );
        }
        if (path === "mutate") {
          return json(await rpc("learning_mutate", token, mutation));
        }
        const payload = body.payload as Record<string, unknown>;
        if (
          !payload.state || typeof payload.state !== "object" ||
          Array.isArray(payload.state) ||
          !validState(payload.state) ||
          new TextEncoder().encode(JSON.stringify(payload.state)).length > 65536
        ) {
          throw new ApiError(
            400,
            "invalid_state",
            "Trạng thái bài làm chưa hợp lệ.",
          );
        }
        const evaluation = JSON.parse(options.evaluate(JSON.stringify({
          activity_id: payload.activity_id,
          content_version: payload.content_version,
          state: payload.state,
        })));
        if (evaluation.error) {
          throw new ApiError(
            422,
            "unsupported_activity",
            "Phiên bản bài học này chưa được hỗ trợ. Hãy cập nhật ứng dụng.",
          );
        }
        evaluation.implementation_hash = options.implementationHash;
        return json(
          await rpc("record_learning_attempt", options.serviceKey, {
            owner_id: user.id,
            operation_id: body.operation_id,
            payload,
            evaluation,
          }, true),
        );
      }
      throw new ApiError(
        404,
        "route_not_found",
        "Chức năng này không tồn tại.",
      );
    } catch (error) {
      return errorResponse(error);
    }
  };
}
