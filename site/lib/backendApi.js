export function getBackendApiUrl() {
  const useProduction = process.env.SITE_USE_PRODUCTION_BACKEND === "true";
  const apiUrl = useProduction
    ? process.env.SITE_PRODUCTION_BACKEND_API_URL || "https://lend.bcmenu.ro/api"
    : process.env.BACKEND_API_URL || "http://localhost:3000/api";

  return apiUrl.replace(/\/$/, "");
}
