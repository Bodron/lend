import { useEffect, useRef, useState } from "react";

const DEFAULT_CENTER = [26.1025, 44.4268];
const STYLE_URL = "/maps/pinlend-style.json";
const WORKER_URL = "/maps/maplibre-gl-worker.mjs";

function validPoint(point) {
  if (point?.latitude == null || point?.longitude == null || point.latitude === "" || point.longitude === "") return false;
  const latitude = Number(point?.latitude);
  const longitude = Number(point?.longitude);
  return Number.isFinite(latitude) && Number.isFinite(longitude)
    && latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
}

export default function PinlendMap({ points = [], selectedId, onSelect, onMapClick, className = "h-80 w-full", fitBoundsPadding = 55 }) {
  const containerRef = useRef(null);
  const mapRef = useRef(null);
  const libraryRef = useRef(null);
  const markersRef = useRef([]);
  const selectedRef = useRef(selectedId);
  const onSelectRef = useRef(onSelect);
  const onMapClickRef = useRef(onMapClick);
  const [ready, setReady] = useState(false);
  const [loaded, setLoaded] = useState(false);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    onSelectRef.current = onSelect;
    onMapClickRef.current = onMapClick;
  }, [onSelect, onMapClick]);

  useEffect(() => {
    let cancelled = false;
    import("maplibre-gl").then((maplibregl) => {
      if (cancelled || !containerRef.current) return;
      libraryRef.current = maplibregl;
      maplibregl.setWorkerUrl(WORKER_URL);
      const map = new maplibregl.Map({
        container: containerRef.current,
        style: STYLE_URL,
        center: DEFAULT_CENTER,
        zoom: 6,
        maxZoom: 18,
        attributionControl: false,
      });
      mapRef.current = map;
      map.addControl(new maplibregl.NavigationControl({ showCompass: false }), "top-right");
      map.addControl(new maplibregl.AttributionControl({ compact: false }), "bottom-right");
      map.on("load", () => {
        setLoaded(true);
        setFailed(false);
      });
      map.on("error", (event) => {
        console.error("Eroare la încărcarea hărții:", event.error);
        if (!map.isStyleLoaded()) setFailed(true);
      });
      map.on("click", (event) => onMapClickRef.current?.({ latitude: event.lngLat.lat, longitude: event.lngLat.lng }));
      setReady(true);
    }).catch(() => { if (!cancelled) setFailed(true); });
    return () => {
      cancelled = true;
      markersRef.current.forEach(({ marker }) => marker.remove());
      markersRef.current = [];
      mapRef.current?.remove();
      mapRef.current = null;
    };
  }, []);

  useEffect(() => {
    const map = mapRef.current;
    const maplibregl = libraryRef.current;
    if (!ready || !map || !maplibregl) return;
    markersRef.current.forEach(({ marker }) => marker.remove());
    const validPoints = points.filter(validPoint);
    markersRef.current = validPoints.map((point) => {
      const element = document.createElement("button");
      element.type = "button";
      element.className = "pinlend-map-marker";
      element.setAttribute("aria-label", point.title || "Locație pe hartă");
      element.addEventListener("click", (event) => {
        event.stopPropagation();
        onSelectRef.current?.(point.id);
      });
      const marker = new maplibregl.Marker({ element, anchor: "bottom" })
        .setLngLat([Number(point.longitude), Number(point.latitude)])
        .addTo(map);
      return { id: point.id, element, marker };
    });
    if (validPoints.length === 1) {
      map.jumpTo({ center: [Number(validPoints[0].longitude), Number(validPoints[0].latitude)], zoom: 13 });
    } else if (validPoints.length > 1) {
      const bounds = new maplibregl.LngLatBounds();
      validPoints.forEach((point) => bounds.extend([Number(point.longitude), Number(point.latitude)]));
      map.fitBounds(bounds, { padding: fitBoundsPadding, maxZoom: 13, duration: 0 });
    }
    return () => {
      markersRef.current.forEach(({ marker }) => marker.remove());
      markersRef.current = [];
    };
  }, [points, ready, fitBoundsPadding]);

  useEffect(() => {
    markersRef.current.forEach(({ id, element }) => {
      element.classList.toggle("pinlend-map-marker-selected", id === selectedId);
      element.setAttribute("aria-pressed", String(id === selectedId));
    });
    if (selectedId && selectedRef.current && selectedId !== selectedRef.current) {
      const marker = markersRef.current.find(({ id }) => id === selectedId);
      if (marker) mapRef.current?.flyTo({ center: marker.marker.getLngLat(), zoom: Math.max(mapRef.current.getZoom(), 12), duration: 550 });
    }
    selectedRef.current = selectedId;
  }, [selectedId, ready, points]);

  return <div className={`relative overflow-hidden rounded-xl bg-[#E8EDF3] ${className}`}>
    <div aria-label="Harta anunțurilor" className="h-full w-full" ref={containerRef} />
    {(failed || !loaded) && <div className="pointer-events-none absolute inset-0 flex items-center justify-center bg-[#E8EDF3] text-sm font-semibold text-[#434750]" role="status">{failed ? "Harta nu este disponibilă momentan." : "Se încarcă harta..."}</div>}
  </div>;
}
