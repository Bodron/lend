import { getBackendApiUrl } from "../../../lib/backendApi";
import { invalidatePublicProductsCache } from "../../../lib/publicProductsServer";

export const config = { api: { bodyParser: { sizeLimit: "2mb" } } };

const cookieName = "pinlend_session";

const routes = {
  me: { method: "GET", path: "auth/me" },
  location: { method: "PATCH", path: "auth/me/location" },
  avatar: { method: "PATCH", path: "auth/me/avatar" },
  identityStatus: { method: "GET", path: "payments/identity/status" },
  identityStart: { method: "POST", path: "payments/identity/start" },
  connectStatus: { method: "GET", path: "payments/connect/status" },
  connectStart: { method: "POST", path: "payments/connect/onboarding-link" },
  connectDashboard: { method: "POST", path: "payments/connect/login-link" },
  payout: { method: "POST", path: "payments/payouts/request" },
  orders: { method: "GET", path: "rental-orders/owned" },
  renterOrders: { method: "GET", path: "rental-orders/me" },
  listings: { method: "GET", path: "products/me" },
  paymentConfig: { method: "GET", path: "payments/config" },
  rentalCreate: { method: "POST", path: "rental-orders" },
  messageThreads: { method: "GET", path: "messages" },
  messageSend: { method: "POST", path: "messages" },
  productCreate: { method: "POST", path: "products" },
  uploadUrl: { method: "POST", path: "storage/uploads" },
  viewingList: { method: "GET", path: "viewings/me" },
  viewingCreate: { method: "POST", path: "viewings" },
  roommateMine: { method: "GET", path: "roommate-posts/me" },
  roommateCreate: { method: "POST", path: "roommate-posts" },
  offerCreate: { method: "POST", path: "messages/offers" },
  favoritesList: { method: "GET", path: "favorites" },
  favoritesImport: { method: "POST", path: "favorites/import" },
};

const validId = (value) => typeof value === "string" && /^[a-f\d]{24}$/i.test(value);

async function uploadRentalContract(req, res, apiUrl, token) {
  const { orderId, pdfBase64 } = req.body || {};
  if (!validId(orderId) || typeof pdfBase64 !== "string" || !/^[A-Za-z0-9+/]+={0,2}$/.test(pdfBase64)) {
    return res.status(400).json({ message: "Contractul nu este valid." });
  }
  const pdf = Buffer.from(pdfBase64, "base64");
  if (pdf.length < 100 || pdf.length > 900_000 || pdf.subarray(0, 5).toString() !== "%PDF-") {
    return res.status(400).json({ message: "Fișierul PDF nu este valid." });
  }

  try {
    const uploadResponse = await fetch(`${apiUrl}/storage/uploads`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({ fileName: `contract-${orderId}.pdf`, contentType: "application/pdf", size: pdf.length }),
      signal: AbortSignal.timeout(12000),
    });
    const upload = await uploadResponse.json().catch(() => ({}));
    if (!uploadResponse.ok) return res.status(uploadResponse.status).json({ message: upload.message || "Nu am putut pregăti contractul." });
    if (!upload.uploadUrl || !upload.key || !upload.readableUrl) throw new Error("Invalid upload response");

    const storageResponse = await fetch(upload.uploadUrl, {
      method: "PUT",
      headers: upload.headers || { "Content-Type": "application/pdf" },
      body: pdf,
      signal: AbortSignal.timeout(30000),
    });
    if (!storageResponse.ok) throw new Error(`Contract upload failed (${storageResponse.status})`);

    const contractResponse = await fetch(`${apiUrl}/rental-orders/${orderId}/contract`, {
      method: "PATCH",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({ key: upload.key, url: upload.readableUrl, contentType: "application/pdf" }),
      signal: AbortSignal.timeout(12000),
    });
    const order = await contractResponse.json().catch(() => ({}));
    return res.status(contractResponse.status).json(contractResponse.ok ? order : { message: order.message || "Nu am putut atașa contractul." });
  } catch (error) {
    console.error("Rental contract upload failed:", error);
    return res.status(502).json({ message: "Nu am putut încărca contractul. Încearcă din nou." });
  }
}

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
  const orderId = req.body?.orderId;
  const orderActions = {
    rentalPaymentAuthorized: "payment-authorized",
    rentalRenterReady: "renter-ready",
    rentalAccept: "accept",
    rentalReject: "reject",
  };
  let route = authAction ? { method: "POST", path: `auth/${action}` } : routes[action];
  if (Object.hasOwn(orderActions, action)) {
    if (!validId(orderId)) return res.status(400).json({ message: "Închirierea nu este validă." });
    route = { method: "PATCH", path: `rental-orders/${orderId}/${orderActions[action]}` };
  }
  if (action === "rentalAvailability") {
    const { productId, from, to } = req.query;
    if (!validId(productId) || !/^\d{4}-\d{2}-\d{2}$/.test(from || "") || !/^\d{4}-\d{2}-\d{2}$/.test(to || "")) {
      return res.status(400).json({ message: "Perioada nu este validă." });
    }
    route = { method: "GET", path: `rental-orders/products/${productId}/availability?${new URLSearchParams({ from, to })}` };
  }
  if (action === "messageThread" || action === "messageDelete") {
    const { productId, roommateInterestId, participantId } = req.query;
    if (!validId(productId) || (roommateInterestId && !validId(roommateInterestId)) || (participantId && !validId(participantId))) {
      return res.status(400).json({ message: "Conversația nu este validă." });
    }
    const params = new URLSearchParams();
    if (roommateInterestId) params.set("roommateInterestId", roommateInterestId);
    if (participantId) params.set("participantId", participantId);
    const query = params.size ? `?${params}` : "";
    route = {
      method: action === "messageDelete" ? "DELETE" : "GET",
      path: `messages/product/${productId}${query}`,
    };
  }
  const resourceActions = {
    productUpdate: { method: "PATCH", path: (id) => `products/${id}` },
    availabilityBlock: { method: "POST", path: (id) => `rental-orders/products/${id}/availability-blocks` },
    availabilityDelete: { method: "DELETE", path: (id) => `rental-orders/availability-blocks/${id}` },
    reviewEligibility: { method: "GET", path: (id) => `reviews/product/${id}/eligibility` },
    reviewCreate: { method: "POST", path: (id) => `reviews/product/${id}` },
    roommateInterest: { method: "POST", path: (id) => `roommate-posts/${id}/interests` },
    roommateClose: { method: "PATCH", path: (id) => `roommate-posts/${id}/close` },
    viewingAccept: { method: "PATCH", path: (id) => `viewings/${id}/accept` },
    viewingReject: { method: "PATCH", path: (id) => `viewings/${id}/reject` },
    viewingPropose: { method: "PATCH", path: (id) => `viewings/${id}/propose` },
    viewingAcceptProposal: { method: "PATCH", path: (id) => `viewings/${id}/accept-proposal` },
    viewingDeclineProposal: { method: "PATCH", path: (id) => `viewings/${id}/decline-proposal` },
    viewingCancel: { method: "PATCH", path: (id) => `viewings/${id}/cancel` },
    viewingComplete: { method: "PATCH", path: (id) => `viewings/${id}/complete` },
    viewingPayment: { method: "POST", path: (id) => `viewings/${id}/payment` },
    viewingPaymentConfirmed: { method: "PATCH", path: (id) => `viewings/${id}/payment-confirmed` },
    viewingIdentityConfirmed: { method: "PATCH", path: (id) => `viewings/${id}/identity-confirmed` },
    offerAccept: { method: "PATCH", path: (id) => `messages/offers/${id}/accept` },
    offerReject: { method: "PATCH", path: (id) => `messages/offers/${id}/reject` },
    offerClaim: { method: "PATCH", path: (id) => `messages/offers/${id}/claim` },
    rentalComplete: { method: "PATCH", path: (id) => `rental-orders/${id}/status` },
    favoriteAdd: { method: "PUT", path: (id) => `favorites/${id}` },
    favoriteRemove: { method: "DELETE", path: (id) => `favorites/${id}` },
  };
  if (Object.hasOwn(resourceActions, action)) {
    if (!validId(req.body?.id) && !validId(req.query.id)) return res.status(400).json({ message: "Identificator invalid." });
    const { method, path } = resourceActions[action];
    route = { method, path: path(req.body?.id || req.query.id) };
  }
  if (action === "contractUpload") route = { method: "POST", path: "" };
  if (!route) return res.status(404).json({ message: "Acțiune necunoscută." });
  if (req.method !== route.method) return res.status(405).json({ message: "Metodă nepermisă." });

  const token = req.cookies[cookieName];
  if (!authAction && !token) return res.status(401).json({ message: "Autentifică-te pentru a continua." });
  const apiUrl = getBackendApiUrl();
  if (action === "contractUpload") return uploadRentalContract(req, res, apiUrl, token);

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
    if (action === "productCreate" || action === "productUpdate") invalidatePublicProductsCache();
    return res.status(200).json(payload);
  } catch (error) {
    console.error("Account API request failed:", action, error);
    return res.status(502).json({ message: "Serverul nu răspunde. Încearcă din nou." });
  }
}
