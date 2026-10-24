export async function accountRequest(action, options = {}) {
  const response = await fetch(`/api/account/${action}`, {
    credentials: "same-origin",
    cache: "no-store",
    ...options,
    headers: { ...(options.body ? { "Content-Type": "application/json" } : {}), ...options.headers },
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message = Array.isArray(data.message) ? data.message.join(" ") : data.message;
    const error = new Error(message || "Operațiunea nu a reușit.");
    error.status = response.status;
    throw error;
  }
  return data;
}

export function requireLogin(error, returnTo) {
  if (error?.status !== 401) return false;
  window.location.assign(`/account?returnTo=${encodeURIComponent(returnTo)}`);
  return true;
}
