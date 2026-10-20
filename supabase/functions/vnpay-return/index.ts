// // Browser redirects are informational only. Only signed IPNs activate a subscription.
// Deno.serve(() => new Response(`<!doctype html><html lang="vi"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>MathLingo</title><body style="font-family:system-ui;max-width:480px;margin:80px auto;padding:24px"><h1>Quay lại MathLingo</h1><p>Bạn có thể đóng trang này và trở lại ứng dụng, chọn “Kiểm tra trạng thái” trong Gói học tập.</p><p>Quyền học sẽ cập nhật sau khi ngân hàng và máy chủ xác minh giao dịch. Không thanh toán lại nếu tài khoản đã bị trừ tiền.</p></body></html>`, {
//   headers: { 'Content-Type': 'text/html; charset=utf-8', 'Content-Security-Policy': "default-src 'none'; style-src 'unsafe-inline'", 'X-Content-Type-Options': 'nosniff' },
// }));
Deno.serve(() => new Response(null, {
  status: 302,
  headers: { Location: 'mathlingo://payment-result' },
}));
