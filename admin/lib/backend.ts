export const COOKIE = "lend_admin_session";
export const apiBase = (process.env.BACKEND_API_URL || "http://localhost:3000/api").replace(/\/$/, "");

export async function backend(path: string, token: string, init: RequestInit = {}) {
  return fetch(`${apiBase}${path}`, {
    ...init, cache: "no-store",
    headers: { Authorization: `Bearer ${token}`, ...(init.body ? { "Content-Type": "application/json" } : {}) },
  });
}

export async function publicBackend(path: string, init: RequestInit = {}) {
  return fetch(`${apiBase}${path}`, {
    ...init, cache: "no-store",
    headers: { "Content-Type": "application/json" },
  });
}
