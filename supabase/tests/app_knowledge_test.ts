import { answerAppQuestion } from "../functions/tutor-chat/app_knowledge.ts";
import { createTutorHandler } from "../functions/tutor-chat/handler.ts";
function assert(value: unknown): asserts value {
  if (!value) throw new Error("Assertion failed");
}
Deno.test("app keywords support Vietnamese with accents, without accents and mixed case", () => {
  for (
    const question of [
      "XP được tính ra sao?",
      "xp duoc tinh ra sao",
      "TẠI SAO KHÔNG CỘNG XP?",
    ]
  ) {
    assert(answerAppQuestion(question)?.includes("30 XP"));
  }
  assert(answerAppQuestion("Cách sao lưu tiến độ app?")?.includes("sao lưu"));
  assert(answerAppQuestion("App có bao nhiêu chủ đề?")?.includes("20 chủ đề"));
  assert(
    answerAppQuestion("App có bao nhiêu chủ đề?")?.includes("139 hoạt động"),
  );
  assert(
    answerAppQuestion("Cách luyện nói tiếng Anh trong app?")?.includes(
      "không phải điểm",
    ),
  );
  assert(
    answerAppQuestion("Tôi không nhận được mã xác nhận")?.includes("6–10"),
  );
  assert(
    answerAppQuestion("Cài đặt API key Gemini ở đâu?")?.includes(
      "không cần nhập API key",
    ),
  );
});
Deno.test("normal learning questions and programming mentions stay with Gemini", () => {
  for (
    const question of [
      "Giải x + 3 = 7",
      "Cho ví dụ Python gửi email",
      "Tại sao góc tam giác có tổng 180 độ?",
    ]
  ) assert(answerAppQuestion(question) === null);
});

Deno.test("authenticated app FAQ uses curated guidance without a Gemini request", async () => {
  let calls = 0;
  const handler = createTutorHandler({
    url: "https://cloud.example",
    publishableKey: "fixture",
    geminiKey: "",
    model: "gemini-3.5-flash-lite",
    // deno-lint-ignore require-await -- Match the fetch contract.
    fetch: async (input) => {
      calls++;
      if (String(input).endsWith("/auth/v1/user")) {
        return Response.json({ id: "11111111-1111-4111-8111-111111111111" });
      }
      if (String(input).includes("get_my_access")) {
        return Response.json([{ status: "active" }]);
      }
      throw new Error("FAQ must not call Gemini");
    },
  });
  const response = await handler(
    new Request("https://cloud.example/functions/v1/tutor-chat", {
      method: "POST",
      headers: {
        Authorization: "Bearer fixture",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        messages: [{
          role: "user",
          content: "Cách lưu tiến độ hoặc sao lưu trong app?",
        }],
      }),
    }),
  );
  const body = await response.json();
  assert(response.status === 200 && body.source === "app_guide");
  assert(body.text.includes("một tiến độ học"));
  assert(calls === 2);
});
