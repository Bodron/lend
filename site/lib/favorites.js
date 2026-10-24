import { accountRequest } from "./accountRequest";

const key = "pinlend_favorite_product_ids";

function legacyIds() {
  if (typeof window === "undefined") return [];
  try {
    const value = JSON.parse(window.localStorage.getItem(key) || "[]");
    return Array.isArray(value) ? value.filter((id) => typeof id === "string" && /^[a-f\d]{24}$/i.test(id)) : [];
  } catch { return []; }
}

export async function favoriteIds() {
  const oldIds = legacyIds();
  if (oldIds.length) {
    const unique = [...new Set(oldIds)];
    let result;
    for (let index = 0; index < unique.length; index += 200) {
      result = await accountRequest("favoritesImport", {
        method: "POST",
        body: JSON.stringify({ productIds: unique.slice(index, index + 200) }),
      });
    }
    window.localStorage.removeItem(key);
    return result.productIds || [];
  }
  const result = await accountRequest("favoritesList");
  return result.productIds || [];
}

export async function setFavorite(id, saved) {
  await accountRequest(saved ? "favoriteAdd" : "favoriteRemove", {
    method: saved ? "PUT" : "DELETE",
    body: JSON.stringify({ id }),
  });
  window.dispatchEvent(new Event("pinlend:favorites"));
  return saved;
}
