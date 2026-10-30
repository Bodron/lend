import Head from "next/head";
import dynamic from "next/dynamic";
import FormSelect from "../components/FormSelect";
import { Input } from "../components/ui/input";
import Link from "next/link";
import PublicHeader from "../components/PublicHeader";
import ListingCard from "../components/ListingCard";
import { getPublicProducts } from "../lib/publicProductsServer";
import { getBackendApiUrl } from "../lib/backendApi";
import { useMemo, useState } from "react";
import { useRouter } from "next/router";
import { useToastError } from "../lib/useToastError";

const ListingMapExplore = dynamic(() => import("../components/ListingMapExplore"), {
  ssr: false,
  loading: () => <div className="mb-8 h-[480px] animate-pulse rounded-2xl bg-[#E8EDF3] sm:h-[520px] lg:h-[560px]" />,
});

const copy = {
  ro: {
    title: "Anunțuri", metaTitle: "Anunțuri PINLEND | Obiecte disponibile pentru închiriere",
    metaDescription: "Explorează anunțurile PINLEND cu obiecte verificate pentru închiriere.",
    search: "Caută anunțuri", searchPlaceholder: "Ce cauți?", city: "Oraș", anyCity: "Orice oraș",
    maxPrice: "Preț maxim / zi", maxPriceLabel: "Preț maxim pe zi", anyPrice: "Orice preț",
    oneResult: "anunț găsit", manyResults: "anunțuri găsite", radius: "Rază", radiusLabel: "Rază în kilometri",
    locating: "Se caută...", nearbyActive: "Lângă mine activ", nearby: "Lângă mine",
    hideMap: "Ascunde harta", showMap: "Vezi harta", favorites: "Favorite", reset: "Resetează",
    noMap: "Nu sunt anunțuri cu locație pe hartă.", map: "Harta", view: "Vezi",
    approximateLocation: "locație aproximativă", previousMapCards: "Anunțurile anterioare", nextMapCards: "Anunțurile următoare", mapCards: "Anunțuri pe hartă",
    loadError: "Nu am putut încărca anunțurile. Încearcă din nou.", retry: "Reîncearcă",
    empty: "Nu am găsit anunțuri pentru filtrele alese.", noImage: "Fără imagine",
    searchHint: "Caută după nume, categorie sau oraș", suggestions: "Sugestii de căutare",
    clearSearch: "Șterge căutarea", clearFilters: "Șterge filtrele", noResultsHint: "Încearcă un termen mai scurt sau elimină un filtru.",
    citySuggestion: "Oraș", listingSuggestion: "Anunț", categorySuggestion: "Categorie", activeFilters: "Filtre active",
    details: "Vezi detalii", detailsLabel: "Vezi detaliile anunțului", unknownCity: "Oraș nespecificat",
    ready: "Gata să împarți?", start: "Începe acum", navigation: "Navigare",
    emailPlaceholder: "Introdu adresa de email", privacy: "Confidențialitate", terms: "Termeni", support: "Suport",
    copyright: "© 2026 PINLEND. Construit pentru economia de sharing.",
  },
  en: {
    title: "Listings", metaTitle: "PINLEND listings | Items available to rent",
    metaDescription: "Explore verified items available to rent on PINLEND.",
    search: "Search listings", searchPlaceholder: "What are you looking for?", city: "City", anyCity: "Any city",
    maxPrice: "Maximum price / day", maxPriceLabel: "Maximum daily price", anyPrice: "Any price",
    oneResult: "listing found", manyResults: "listings found", radius: "Radius", radiusLabel: "Radius in kilometers",
    locating: "Locating...", nearbyActive: "Nearby active", nearby: "Nearby",
    hideMap: "Hide map", showMap: "View map", favorites: "Favorites", reset: "Reset",
    noMap: "No listings with a map location.", map: "Map of", view: "View",
    approximateLocation: "approximate location", previousMapCards: "Previous listings", nextMapCards: "Next listings", mapCards: "Listings on the map",
    loadError: "We couldn't load the listings. Please try again.", retry: "Try again",
    empty: "No listings match your filters.", noImage: "No image",
    searchHint: "Search by name, category or city", suggestions: "Search suggestions",
    clearSearch: "Clear search", clearFilters: "Clear filters", noResultsHint: "Try a shorter search or remove a filter.",
    citySuggestion: "City", listingSuggestion: "Listing", categorySuggestion: "Category", activeFilters: "Active filters",
    details: "View details", detailsLabel: "View listing details for", unknownCity: "City not specified",
    ready: "Ready to share?", start: "Get started", navigation: "Navigation",
    emailPlaceholder: "Enter your email address", privacy: "Privacy", terms: "Terms", support: "Support",
    copyright: "© 2026 PINLEND. Built for the sharing economy.",
  },
};

const cardAspects = ["aspect-[4/5]", "aspect-[3/4]", "aspect-square", "aspect-[4/3]"];
const cardOffsets = ["", "md:mt-12", "", "xl:mt-16"];
const existingEnglishCategoryNames = {
  electronice: "Electronics",
  "gaming-console": "Gaming & Consoles",
  "foto-video": "Photo & Video",
  drone: "Drones",
  unelte: "Tools",
  "casa-gradina": "Home & Garden",
  "sport-outdoor": "Sports & Outdoors",
  masini: "Cars",
  imobiliare: "Real Estate",
  evenimente: "Events",
  mobilitate: "Mobility",
  "fashion-accesorii": "Fashion & Accessories",
  "copii-familie": "Kids & Family",
  "muzica-audio": "Music & Audio",
};
function distanceKm(lat1, lng1, lat2, lng2) {
  if (![lat1, lng1, lat2, lng2].every(Number.isFinite)) return Infinity;
  const rad = Math.PI / 180;
  const a = Math.sin((lat2 - lat1) * rad / 2) ** 2
    + Math.cos(lat1 * rad) * Math.cos(lat2 * rad) * Math.sin((lng2 - lng1) * rad / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function normalizeSearchText(value) {
  return String(value ?? "").normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .toLocaleLowerCase().replace(/[^\p{L}\p{N}]+/gu, " ").trim();
}

function matchesSearch(value, query) {
  const normalizedValue = normalizeSearchText(value);
  const normalizedQuery = normalizeSearchText(query);
  if (!normalizedQuery) return true;
  if (normalizedValue.includes(normalizedQuery)) return true;
  if (normalizedValue.replaceAll(" ", "").includes(normalizedQuery.replaceAll(" ", ""))) return true;
  return normalizedQuery.split(" ").every((word) => normalizedValue.includes(word));
}

export async function getServerSideProps({ res, locale }) {
  try {
    const [products, categoryResponse] = await Promise.all([
      getPublicProducts(),
      fetch(`${getBackendApiUrl()}/categories`, { signal: AbortSignal.timeout(8000) })
        .then((response) => response.ok ? response.json() : [])
        .catch(() => []),
    ]);
    const categoryBySlug = new Map(
      (Array.isArray(categoryResponse) ? categoryResponse : []).map((category) => [category.slug, category]),
    );

    const listings = products
      .filter((product) => product && product.isClosedByAdmin !== true)
      .map((product, index) => {
        const image = Array.isArray(product.images)
          ? product.images.find((item) => item?.url && item.type !== "video" && item.contentType?.startsWith("image/"))
          : null;
        return {
          id: String(product._id ?? product.id ?? ""),
          slug: String(product.slug ?? ""),
          title: String(product.title ?? ""),
          category: String(product.categorySlug ?? ""),
          categoryLabel: String(
            (locale === "en"
              ? categoryBySlug.get(product.categorySlug)?.nameEn || existingEnglishCategoryNames[product.categorySlug]
              : categoryBySlug.get(product.categorySlug)?.name)
            || categoryBySlug.get(product.categorySlug)?.name
            || product.category
            || product.categorySlug
            || "",
          ),
          city: String(product.city ?? "").trim(),
          priceNumber: Number(product.pricePerDay) || 0,
          latitude: product.latitude ?? null,
          longitude: product.longitude ?? null,
          image: image?.url ?? null,
          aspect: cardAspects[index % cardAspects.length],
          offset: cardOffsets[index % cardOffsets.length],
          price: `${new Intl.NumberFormat(locale === "en" ? "en-GB" : "ro-RO", { maximumFractionDigits: 2 }).format(Number(product.pricePerDay) || 0)} RON / ${locale === "en" ? "DAY" : "ZI"}`,
          text: String(product.description ?? ""),
        };
      })
      .filter((item) => item.id && item.slug && item.title);

    const categories = [
      { id: "all", label: locale === "en" ? "All listings" : "Toate anunțurile" },
      ...Array.from(new Map(listings.filter((item) => item.category).map((item) => [
        item.category,
        { id: item.category, label: item.categoryLabel },
      ])).values()),
    ];

    return { props: { listings, categories, loadError: false } };
  } catch (error) {
    console.error("Could not load archive listings:", error);
    res.statusCode = 503;
    return {
      props: {
        listings: [],
        categories: [{ id: "all", label: locale === "en" ? "All listings" : "Toate anunțurile" }],
        loadError: true,
      },
    };
  }
}

export default function ListingsHome({ listings, categories, loadError }) {
  const { locale } = useRouter();
  const t = copy[locale] || copy.ro;
  const [activeFilter, setActiveFilter] = useState("all");
  const [search, setSearch] = useState("");
  const [searchOpen, setSearchOpen] = useState(false);
  const [highlightedSuggestion, setHighlightedSuggestion] = useState(-1);
  const [city, setCity] = useState("");
  const [maxPrice, setMaxPrice] = useState("");
  const [position, setPosition] = useState(null);
  const [radiusKm, setRadiusKm] = useState(25);
  const [showMap, setShowMap] = useState(true);
  const [locating, setLocating] = useState(false);
  const [, setLocationError] = useToastError();
  const [cursor, setCursor] = useState({ x: 0, y: 0, visible: false });

  function toggleNearby() {
    if (position) {
      setPosition(null);
      setLocationError("");
      return;
    }
    if (!navigator.geolocation) {
      setLocationError("Browserul nu poate accesa locația.");
      return;
    }
    setLocating(true);
    setLocationError("");
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => { setPosition({ latitude: coords.latitude, longitude: coords.longitude }); setLocating(false); },
      () => { setLocationError("Nu am putut obține locația. Verifică permisiunea browserului."); setLocating(false); },
      { enableHighAccuracy: false, timeout: 10000 },
    );
  }

  function resetFilters() {
    setActiveFilter("all");
    setSearch("");
    setCity("");
    setMaxPrice("");
    setPosition(null);
    setRadiusKm(25);
    setLocationError("");
  }

  const visibleListings = useMemo(() => {
    const filtered = listings.filter((item) =>
      (activeFilter === "all" || item.category === activeFilter)
      && matchesSearch(`${item.title} ${item.categoryLabel} ${item.city} ${item.text}`, search)
      && matchesSearch(item.city, city)
      && (!maxPrice || item.priceNumber <= Number(maxPrice))
      && (!position || (item.latitude != null && item.longitude != null && distanceKm(position.latitude, position.longitude, Number(item.latitude), Number(item.longitude)) <= radiusKm)));
    if (search.trim()) {
      filtered.sort((a, b) => {
        const score = (item) => {
          if (matchesSearch(item.title, search)) return 0;
          if (matchesSearch(item.categoryLabel, search)) return 1;
          if (matchesSearch(item.city, search)) return 2;
          return 3;
        };
        return score(a) - score(b);
      });
    }
    return filtered;
  }, [activeFilter, listings, search, city, maxPrice, position, radiusKm]);
  const hasSearchFilters = Boolean(activeFilter !== "all" || search || city || maxPrice || position);
  const cityOptions = useMemo(() => [...new Set(listings.map((item) => item.city).filter(Boolean))].sort(), [listings]);
  const suggestions = useMemo(() => {
    if (!search.trim()) return [];
    const matchingCategories = categories.slice(1)
      .filter((item) => matchesSearch(item.label, search))
      .slice(0, 2).map((item) => ({ kind: "category", label: item.label, value: item.id }));
    const matchingListings = listings.filter((item) => matchesSearch(item.title, search))
      .slice(0, 4).map((item) => ({ kind: "listing", label: item.title, value: item.title }));
    const matchingCities = cityOptions.filter((item) => matchesSearch(item, search))
      .slice(0, 2).map((item) => ({ kind: "city", label: item, value: item }));
    return [...matchingCategories, ...matchingListings, ...matchingCities].slice(0, 6);
  }, [categories, cityOptions, listings, search]);

  function chooseSuggestion(suggestion) {
    if (suggestion.kind === "category") {
      setActiveFilter(suggestion.value);
      setSearch("");
    } else if (suggestion.kind === "city") {
      setCity(suggestion.value);
      setSearch("");
    } else {
      setSearch(suggestion.value);
    }
    setSearchOpen(false);
    setHighlightedSuggestion(-1);
  }


  return (
    <>
      <Head>
        <title>{t.metaTitle}</title>
        <meta
          name="description"
          content={t.metaDescription}
        />
      </Head>

      <PublicHeader current="/" />

      <main className="w-full bg-[#f9f9f9] pt-20">
        <section className="flex flex-col items-start gap-8 px-5 py-16 md:px-20 md:py-20">
          <div>
            <h1 className="archive-title font-display font-extrabold uppercase text-black">
              {t.title}
            </h1>
          </div>

          <div className="flex w-full flex-wrap gap-3">
            {categories.map((category) => {
              const active = activeFilter === category.id;
              return (
                <button
                  className={`cursor-pointer rounded-full border px-5 py-2 font-mono text-xs uppercase tracking-widest transition-all duration-300 hover:-translate-y-0.5 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#30578F] ${
                    active
                      ? "border-black bg-black text-white"
                      : "border-black/20 text-black hover:border-black"
                  }`}
                  key={category.id}
                  onClick={() => setActiveFilter(category.id)}
                  type="button"
                >
                  {category.label}
                </button>
              );
            })}
          </div>
          <div className="grid w-full gap-5 md:grid-cols-[minmax(0,1.5fr)_minmax(0,1fr)_minmax(0,0.8fr)] md:gap-8">
            <div className="relative z-30 min-w-0" onBlur={(event) => { if (!event.currentTarget.contains(event.relatedTarget)) setSearchOpen(false); }}>
              <label className="block font-mono text-[11px] uppercase tracking-widest text-black" htmlFor="listing-search">{t.search}</label>
              <div className="mt-2 flex items-center gap-2 border-b border-black/30 pb-3 focus-within:border-[#30578F]">
                <span aria-hidden="true" className="material-symbols-outlined text-[20px] text-black/55">search</span>
                <Input
                  aria-autocomplete="list"
                  aria-controls="listing-search-suggestions"
                  aria-expanded={searchOpen && suggestions.length > 0}
                  aria-label={t.search}
                  autoComplete="off"
                  className="h-auto min-w-0 flex-1 rounded-none border-0 bg-transparent px-0 py-0 text-base text-black outline-none focus-visible:border-transparent focus-visible:ring-0 placeholder:text-black/45"
                  id="listing-search"
                  onChange={(event) => { setSearch(event.target.value); setSearchOpen(true); setHighlightedSuggestion(-1); }}
                  onFocus={() => setSearchOpen(true)}
                  onKeyDown={(event) => {
                    if (event.key === "Escape") { setSearchOpen(false); setHighlightedSuggestion(-1); }
                    if (event.key === "ArrowDown" && suggestions.length) { event.preventDefault(); setSearchOpen(true); setHighlightedSuggestion((index) => Math.min(index + 1, suggestions.length - 1)); }
                    if (event.key === "ArrowUp" && suggestions.length) { event.preventDefault(); setHighlightedSuggestion((index) => Math.max(index - 1, 0)); }
                    if (event.key === "Enter" && searchOpen && highlightedSuggestion >= 0) { event.preventDefault(); chooseSuggestion(suggestions[highlightedSuggestion]); }
                  }}
                  placeholder={t.searchPlaceholder}
                  role="combobox"
                  type="text"
                  value={search}
                />
                {search && <button aria-label={t.clearSearch} className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-black/55 hover:bg-black/5 hover:text-black" onClick={() => { setSearch(""); setSearchOpen(false); }} type="button"><span aria-hidden="true" className="material-symbols-outlined text-[18px]">close</span></button>}
              </div>
              {searchOpen && suggestions.length > 0 && <div className="absolute inset-x-0 top-full z-40 mt-2 overflow-hidden rounded-xl border border-black/10 bg-white py-2 shadow-xl" id="listing-search-suggestions" role="listbox">
                <p className="px-4 pb-2 font-mono text-[10px] uppercase tracking-widest text-black/45">{t.suggestions}</p>
                {suggestions.map((suggestion, index) => <button
                  aria-selected={highlightedSuggestion === index}
                  className={`flex w-full items-center justify-between gap-3 px-4 py-2.5 text-left text-sm hover:bg-[#edf3fb] ${highlightedSuggestion === index ? "bg-[#edf3fb]" : ""}`}
                  key={`${suggestion.kind}-${suggestion.value}`}
                  onClick={() => chooseSuggestion(suggestion)}
                  onMouseEnter={() => setHighlightedSuggestion(index)}
                  role="option"
                  type="button"
                ><span className="truncate text-black">{suggestion.label}</span><span className="shrink-0 text-[11px] text-black/45">{suggestion.kind === "city" ? t.citySuggestion : suggestion.kind === "category" ? t.categorySuggestion : t.listingSuggestion}</span></button>)}
              </div>}
              <p className="mt-2 text-xs text-black/50">{t.searchHint}</p>
            </div>
            <label className="block min-w-0 border-b border-black/30 pb-3 focus-within:border-black">
              <span className="block font-mono text-[11px] uppercase tracking-widest text-black">{t.city}</span>
              <Input aria-label={t.city} className="mt-2 h-auto w-full rounded-none border-0 bg-transparent px-0 py-0 text-base text-black outline-none focus-visible:border-transparent focus-visible:ring-0 placeholder:text-black/45" list="listing-cities" onChange={(event) => setCity(event.target.value)} placeholder={t.anyCity} value={city} />
              <datalist id="listing-cities">{cityOptions.map((option) => <option key={option} value={option} />)}</datalist>
            </label>
            <label className="block min-w-0 border-b border-black/30 pb-3 focus-within:border-black">
              <span className="block font-mono text-[11px] uppercase tracking-widest text-black">{t.maxPrice}</span>
              <span className="mt-2 flex items-baseline gap-2"><Input aria-label={t.maxPriceLabel} className="h-auto w-full min-w-0 appearance-none rounded-none border-0 bg-transparent px-0 py-0 text-base text-black outline-none focus-visible:border-transparent focus-visible:ring-0 placeholder:text-black/45 [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none" min="1" onChange={(event) => setMaxPrice(event.target.value)} placeholder={t.anyPrice} type="number" value={maxPrice} />{maxPrice && <span className="shrink-0 font-mono text-xs text-black/60">RON</span>}</span>
            </label>
          </div>
          {hasSearchFilters && <div aria-label={t.activeFilters} className="flex w-full flex-wrap items-center gap-2">
            {search && <button className="rounded-full border border-[#30578F]/20 bg-[#edf3fb] px-3 py-1.5 text-xs text-[#30578F] hover:bg-[#dce8f7]" onClick={() => setSearch("")} type="button">{search} <span aria-hidden="true">×</span></button>}
            {activeFilter !== "all" && <button className="rounded-full border border-[#30578F]/20 bg-[#edf3fb] px-3 py-1.5 text-xs text-[#30578F] hover:bg-[#dce8f7]" onClick={() => setActiveFilter("all")} type="button">{categories.find((item) => item.id === activeFilter)?.label} <span aria-hidden="true">×</span></button>}
            {city && <button className="rounded-full border border-[#30578F]/20 bg-[#edf3fb] px-3 py-1.5 text-xs text-[#30578F] hover:bg-[#dce8f7]" onClick={() => setCity("")} type="button">{city} <span aria-hidden="true">×</span></button>}
            {maxPrice && <button className="rounded-full border border-[#30578F]/20 bg-[#edf3fb] px-3 py-1.5 text-xs text-[#30578F] hover:bg-[#dce8f7]" onClick={() => setMaxPrice("")} type="button">≤ {maxPrice} RON <span aria-hidden="true">×</span></button>}
            {position && <button className="rounded-full border border-[#30578F]/20 bg-[#edf3fb] px-3 py-1.5 text-xs text-[#30578F] hover:bg-[#dce8f7]" onClick={() => setPosition(null)} type="button">{t.nearby} · {radiusKm} km <span aria-hidden="true">×</span></button>}
            <button className="ml-1 text-xs font-semibold text-[#30578F] underline-offset-4 hover:underline" onClick={resetFilters} type="button">{t.clearFilters}</button>
          </div>}
          <div className="flex w-full flex-wrap items-center justify-between gap-x-6 gap-y-4 border-b border-black/10 pb-6">
            <p aria-live="polite" className="font-mono text-[11px] uppercase tracking-[0.16em] text-black/55">{visibleListings.length} {visibleListings.length === 1 ? t.oneResult : t.manyResults}</p>
            <div className="flex flex-wrap items-center gap-x-5 gap-y-3">
              {position && <label className="flex items-center gap-2 font-mono text-[11px] uppercase tracking-[0.12em] text-black/60">{t.radius}<FormSelect aria-label={t.radiusLabel} className="border-b border-black/30 bg-transparent py-1 text-black outline-none focus:border-[#30578F]" onChange={(event) => setRadiusKm(Number(event.target.value))} value={radiusKm}><option value={5}>5 km</option><option value={10}>10 km</option><option value={25}>25 km</option><option value={50}>50 km</option><option value={100}>100 km</option></FormSelect></label>}
              <button aria-pressed={Boolean(position)} className={`inline-flex items-center gap-2 border-b py-1 font-mono text-[11px] uppercase tracking-[0.12em] transition-colors ${position ? "border-[#30578F] text-[#30578F]" : "border-transparent text-black/65 hover:border-black hover:text-black"}`} disabled={locating} onClick={toggleNearby} type="button"><span aria-hidden="true" className="material-symbols-outlined text-[18px]">near_me</span>{locating ? t.locating : position ? t.nearbyActive : t.nearby}</button>
              <button aria-pressed={showMap} className={`inline-flex items-center gap-2 border-b py-1 font-mono text-[11px] uppercase tracking-[0.12em] transition-colors ${showMap ? "border-[#30578F] text-[#30578F]" : "border-transparent text-black/65 hover:border-black hover:text-black"}`} onClick={() => setShowMap(!showMap)} type="button"><span aria-hidden="true" className="material-symbols-outlined text-[18px]">map</span>{showMap ? t.hideMap : t.showMap}</button>
              <Link className="inline-flex items-center gap-2 border-b border-transparent py-1 font-mono text-[11px] uppercase tracking-[0.12em] text-black/65 transition-colors hover:border-black hover:text-black" href="/favorite"><span aria-hidden="true" className="material-symbols-outlined text-[18px]">favorite_border</span>{t.favorites}</Link>
              {hasSearchFilters && <button className="border-b border-transparent py-1 font-mono text-[11px] uppercase tracking-[0.12em] text-black/45 transition-colors hover:border-black hover:text-black" onClick={resetFilters} type="button">{t.reset}</button>}
            </div>
          </div>
          
        </section>

        <section className="min-h-screen px-5 pb-32 md:px-20 md:pb-40">
          {showMap && <ListingMapExplore listings={visibleListings} t={t} />}
          {loadError ? (
            <div className="py-16 text-center text-[#444748]">
              <p>{t.loadError}</p>
              <Link className="mt-6 inline-block border border-black px-5 py-2 font-mono text-xs uppercase tracking-widest text-black" href="/">
                {t.retry}
              </Link>
            </div>
          ) : visibleListings.length === 0 ? (
            <div className="mx-auto max-w-lg py-16 text-center text-[#444748]">
              <span aria-hidden="true" className="material-symbols-outlined text-4xl text-[#30578F]">search_off</span>
              <h2 className="mt-3 text-xl font-semibold text-black">{t.empty}</h2>
              <p className="mt-2 text-sm">{t.noResultsHint}</p>
              {hasSearchFilters && <button className="mt-6 rounded-full bg-black px-6 py-3 text-sm font-semibold text-white transition-colors hover:bg-[#30578F]" onClick={resetFilters} type="button">{t.clearFilters}</button>}
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-8 transition-all duration-700 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
              {visibleListings.map((item) => (
                <ListingCard
                  item={item}
                  t={t}
                  key={item.id}
                  onCursorMove={setCursor}
                  onCursorLeave={() => setCursor((current) => ({ ...current, visible: false }))}
                />
              ))}
            </div>
          )}
        </section>

        <CustomCursor cursor={cursor} />
      </main>

      <Footer t={t} />
    </>
  );
}

function CustomCursor({ cursor }) {
  return (
    <div
      className={`pointer-events-none fixed left-0 top-0 z-[100] hidden h-8 w-8 -translate-x-1/2 -translate-y-1/2 items-center justify-center mix-blend-difference transition-opacity duration-300 md:flex ${
        cursor.visible ? "opacity-100" : "opacity-0"
      }`}
      style={{ transform: `translate(${cursor.x}px, ${cursor.y}px) translate(-50%, -50%)` }}
    >
      <div
        className={`h-full w-full rounded-full border-2 border-white transition-transform duration-300 ${
          cursor.visible ? "scale-[2]" : "scale-50"
        }`}
      />
      <span
        className={`material-symbols-outlined absolute text-[12px] text-white transition-opacity duration-300 ${
          cursor.visible ? "opacity-100" : "opacity-0"
        }`}
      >
        add
      </span>
    </div>
  );
}

function Footer({ t }) {
  return (
    <footer className="w-full bg-black px-5 py-32 md:px-20 md:py-40">
      <div className="mb-12 flex flex-col items-start justify-between gap-10 border-b border-white/10 pb-12 lg:flex-row lg:items-end">
        <h2 className="max-w-4xl font-display text-6xl font-extrabold uppercase leading-none text-white md:text-[120px]">
          {t.ready}
        </h2>
        <Link
          className="bg-[#4A70A9] px-12 py-6 font-mono text-xs uppercase tracking-widest text-white transition-colors duration-300 hover:bg-white hover:text-[#30578F]"
          href="/download"
        >
          {t.start}
        </Link>
      </div>
      <div className="mb-20 grid grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-4">
        <FooterColumn title="Social">
          <a href="#">Instagram</a>
          <a href="#">Twitter/X</a>
          <a href="#">LinkedIn</a>
        </FooterColumn>
        <FooterColumn title={t.navigation}>
          <Link href="/despre-noi">{t === copy.en ? "About us" : "Despre noi"}</Link>
          <Link href="/features">{t === copy.en ? "Features" : "Funcționalități"}</Link>
          <Link href="/">{t.title}</Link>
        </FooterColumn>
        <div className="flex flex-col gap-6 md:col-span-2">
          <p className="font-mono text-xs uppercase tracking-widest text-white/60">Newsletter</p>
          <form className="relative flex w-full items-center border-b border-white/20">
            <Input
              className="h-auto w-full rounded-none border-0 bg-transparent px-0 py-4 text-xl leading-8 text-white outline-none focus-visible:border-transparent focus-visible:ring-0 transition-colors placeholder:text-white/35"
              placeholder={t.emailPlaceholder}
              type="email"
            />
            <button className="material-symbols-outlined text-white" type="submit">
              arrow_forward
            </button>
          </form>
        </div>
      </div>
      <div className="flex flex-col justify-between gap-8 border-t border-white/5 pt-8 md:flex-row">
        <span className="font-mono text-xs uppercase tracking-widest text-white/40">
          {t.copyright}
        </span>
        <div className="flex flex-wrap gap-6">
          <Link className="font-mono text-xs uppercase tracking-widest text-white/40" href="/privacy-policy">
            {t.privacy}
          </Link>
          <Link className="font-mono text-xs uppercase tracking-widest text-white/40" href="/terms-and-conditions">
            {t.terms}
          </Link>
          <Link className="font-mono text-xs uppercase tracking-widest text-white/40" href="/support">
            {t.support}
          </Link>
        </div>
      </div>
    </footer>
  );
}

function FooterColumn({ title, children }) {
  return (
    <div className="flex flex-col gap-6">
      <p className="font-mono text-xs uppercase tracking-widest text-white/60">{title}</p>
      <div className="flex flex-col gap-2 text-xl leading-8 text-white">{children}</div>
    </div>
  );
}
