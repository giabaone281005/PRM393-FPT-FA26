export const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...cors,
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });
}

export class ApiError extends Error {
  constructor(public status: number, public code: string, message: string) {
    super(message);
  }
}

// Limit the stream itself, including chunked requests without Content-Length.
export async function readJson(
  request: Request,
  limit = 300000,
): Promise<Record<string, unknown>> {
  if (
    !request.headers.get("content-type")?.toLowerCase().startsWith(
      "application/json",
    )
  ) {
    throw new ApiError(415, "json_required", "Vui lòng gửi dữ liệu JSON.");
  }
  const reader = request.body?.getReader();
  if (!reader) {
    throw new ApiError(400, "invalid_payload", "Thiếu dữ liệu yêu cầu.");
  }
  const chunks: Uint8Array[] = [];
  let size = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    size += value.byteLength;
    if (size > limit) {
      await reader.cancel();
      throw new ApiError(
        413,
        "payload_too_large",
        "Dữ liệu quá lớn. Hãy chia thành các lần lưu nhỏ hơn.",
      );
    }
    chunks.push(value);
  }
  const bytes = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.length;
  }
  try {
    const body = JSON.parse(new TextDecoder().decode(bytes));
    if (!body || Array.isArray(body) || typeof body !== "object") {
      throw new Error();
    }
    return body;
  } catch {
    throw new ApiError(400, "invalid_payload", "Dữ liệu gửi lên chưa hợp lệ.");
  }
}

export function errorResponse(error: unknown): Response {
  if (error instanceof ApiError) {
    return json(
      { error: { code: error.code, message: error.message } },
      error.status,
    );
  }
  return json({
    error: {
      code: "server_unavailable",
      message: "Máy chủ chưa xử lý được yêu cầu. Vui lòng thử lại.",
    },
  }, 503);
}
