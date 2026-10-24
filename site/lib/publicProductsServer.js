import { getBackendApiUrl } from "./backendApi";

// Public listing pages share a short-lived server cache. It avoids repeating the
// same backend request during navigation while keeping edits visible quickly.
const CACHE_MS = 10_000;
const cache = globalThis.__pinlendPublicProductsCache ??= { products: null, expiresAt: 0, pending: null, version: 0 };

export function invalidatePublicProductsCache() {
  cache.version += 1;
  cache.products = null;
  cache.expiresAt = 0;
  cache.pending = null;
}

export async function getPublicProducts() {
  if (cache.products && Date.now() < cache.expiresAt) return cache.products;
  if (cache.pending) return cache.pending;

  const request = (async () => {
    const response = await fetch(`${getBackendApiUrl()}/products`, {
      cache: "no-store",
      signal: AbortSignal.timeout(10_000),
    });
    if (!response.ok) throw new Error(`Products API returned ${response.status}`);
    const payload = await response.json();
    if (!Array.isArray(payload)) throw new Error("Products API returned an invalid list");
    return payload;
  })();

  const version = cache.version;
  cache.pending = request;
  try {
    const freshProducts = await request;
    if (cache.version === version) {
      cache.products = freshProducts;
      cache.expiresAt = Date.now() + CACHE_MS;
    }
    return freshProducts;
  } finally {
    if (cache.pending === request) cache.pending = null;
  }
}
