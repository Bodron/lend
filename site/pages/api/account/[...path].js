const cookieName = "pinlend_session";

const routes = {
  me: { method: "GET", path: "auth/me" },
  location: { method: "PATCH", path: "auth/me/location" },
  identityStatus: { method: "GET", path: "payments/identity/status" },
  identityStart: { method: "POST", path: "payments/identity/start" },
  connectStatus: { method: "GET", path: "payments/connect/status" },
  connectStart: { method: "POST", path: "payments/connect/onboarding-link" },
  connectDashboard: { method: "POST", path: "payments/connect/login-link" },
  payout: { method: "POST", path: "payments/payouts/request" },
  orders: { method: "GET", path: "rental-orders/owned" },
  renterOrders: { method: "GET", path: "rental-orders/me" },
  listings: { method: "GET", path: "products/me" },
};

function sessionCookie(value, maxAge) {
  const secure = process.env.NODE_ENV === "production" ? "; Secure" : "";
  return `${cookieName}=${encodeURIComponent(value)}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${maxAge}${secure}`;
}

function sameOrigin(req) {
  const origin = req.headers.origin;
  if (!origin) return true;
  try {
    return new URL(origin).host === req.headers.host;
  } catch {
    return false;
  }
}

export default async function handler(req, res) {
  res.setHeader("Cache-Control", "private, no-store, max-age=0");
  const action = Array.isArray(req.query.path) ? req.query.path.join("/") : "";
  const mutating = req.method !== "GET";
  if (mutating && !sameOrigin(req)) return res.status(403).json({ message: "Cerere respinsă." });

  if (action === "logout") {
    if (req.method !== "POST") return res.status(405).json({ message: "Metodă nepermisă." });
    res.setHeader("Set-Cookie", sessionCookie("", 0));
    return res.status(200).json({ ok: true });
  }

  const authAction = action === "login" || action === "register";
  const route = authAction ? { method: "POST", path: `auth/${action}` } : routes[action];
  if (!route) return res.status(404).json({ message: "Acțiune necunoscută." });
  if (req.method !== route.method) return res.status(405).json({ message: "Metodă nepermisă." });

  const token = req.cookies[cookieName];
  if (!authAction && !token) return res.status(401).json({ message: "Autentifică-te pentru a continua." });
  const apiUrl = (process.env.BACKEND_API_URL || "http://localhost:3000/api").replace(/\/$/, "");

  try {
    const response = await fetch(`${apiUrl}/${route.path}`, {
      method: route.method,
      headers: {
        ...(token && !authAction ? { Authorization: `Bearer ${token}` } : {}),
        ...(mutating ? { "Content-Type": "application/json" } : {}),
      },
      ...(mutating ? { body: JSON.stringify(action === "connectStart" || action === "payout" ? { ...req.body, platform: "web" } : req.body || {}) } : {}),
      cache: "no-store",
      signal: AbortSignal.timeout(action === "payout" ? 30000 : 12000),
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      if (response.status === 401 && !authAction) res.setHeader("Set-Cookie", sessionCookie("", 0));
      return res.status(response.status).json({ message: payload.message || "Operațiunea nu a reușit." });
    }
    if (authAction) {
      if (!payload.accessToken || !payload.user) return res.status(502).json({ message: "Răspuns invalid de la server." });
      res.setHeader("Set-Cookie", sessionCookie(payload.accessToken, 7 * 24 * 60 * 60));
      return res.status(200).json({ user: payload.user });
    }
    return res.status(200).json(payload);
  } catch (error) {
    console.error("Account API request failed:", action, error);
    return res.status(502).json({ message: "Serverul nu răspunde. Încearcă din nou." });
  }
}
