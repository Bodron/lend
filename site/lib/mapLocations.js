// City centers mirror the Flutter explore map for listings without precise coordinates.
const CITY_COORDINATES = {
  bucuresti: [44.4268, 26.1025],
  bucharest: [44.4268, 26.1025],
  "cluj-napoca": [46.7712, 23.6236],
  "cluj napoca": [46.7712, 23.6236],
  brasov: [45.6427, 25.5887],
  timisoara: [45.7489, 21.2087],
  iasi: [47.1585, 27.6014],
  constanta: [44.1598, 28.6348],
  sibiu: [45.7983, 24.1256],
  oradea: [47.0465, 21.9189],
  craiova: [44.3302, 23.7949],
  galati: [45.4353, 28.0080],
  ploiesti: [44.9367, 26.0129],
  pitesti: [44.8565, 24.8692],
  arad: [46.1866, 21.3123],
};

function normalizeCity(value) {
  return String(value || "").trim().toLocaleLowerCase("ro-RO")
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .replace(/[șş]/g, "s").replace(/[țţ]/g, "t");
}

export function listingsWithMapLocations(listings) {
  const cityCounts = new Map();
  return listings.flatMap((item) => {
    if (item.latitude != null && item.longitude != null) {
      const latitude = Number(item.latitude);
      const longitude = Number(item.longitude);
      if (Number.isFinite(latitude) && Number.isFinite(longitude) && Math.abs(latitude) <= 90 && Math.abs(longitude) <= 180) {
        return [{ ...item, latitude, longitude }];
      }
    }
    const city = normalizeCity(item.city);
    const center = CITY_COORDINATES[city];
    if (!center) return [];
    const index = cityCounts.get(city) || 0;
    cityCounts.set(city, index + 1);
    const spread = 0.008 + (index % 5) * 0.004;
    return [{ ...item, latitude: center[0] + spread * (index % 2 === 0 ? 1 : -1), longitude: center[1] + spread * (index % 3 === 0 ? 1 : -1), approximate: true }];
  });
}
