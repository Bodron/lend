/* eslint-disable @next/next/no-img-element */
import Head from "next/head";
import Link from "next/link";
import { useState } from "react";
import BrandLogo from "../../components/BrandLogo";

const money = new Intl.NumberFormat("ro-RO", { maximumFractionDigits: 2 });

function formatRon(value) {
  return `${money.format(Number(value) || 0)} RON`;
}

function availableModes(product) {
  const configured = Array.isArray(product.rentalModes) ? product.rentalModes : ["day"];
  const modes = [];
  if (configured.includes("hour") && product.pricePerDay > 0) {
    modes.push({ id: "hour", label: "Oră", price: Math.max(1, Math.round(product.pricePerDay / 8)), suffix: "/ oră" });
  }
  if (configured.includes("day") && product.pricePerDay > 0) {
    modes.push({ id: "day", label: "Zi", price: product.pricePerDay, suffix: "/ zi" });
  }
  if (configured.includes("month") && product.pricePerMonth > 0) {
    modes.push({ id: "month", label: "Lună", price: product.pricePerMonth, suffix: "/ lună" });
  }
  return modes;
}

export async function getServerSideProps({ params, res }) {
  const apiUrl = (process.env.BACKEND_API_URL || "http://localhost:3000/api").replace(/\/$/, "");
  const slug = String(params.slug || "");

  try {
    const response = await fetch(`${apiUrl}/products/${encodeURIComponent(slug)}`, {
      cache: "no-store",
      signal: AbortSignal.timeout(10000),
    });
    if (response.status === 404) return { notFound: true };
    if (!response.ok) throw new Error(`Products API returned ${response.status}`);

    const product = await response.json();
    if (!product || product.isClosedByAdmin === true) return { notFound: true };

    let reviews = [];
    let ownerListings = [];
    const productId = String(product._id ?? product.id ?? "");
    const [reviewsResult, listingsResult] = await Promise.allSettled([
      productId
        ? fetch(`${apiUrl}/reviews/product/${encodeURIComponent(productId)}`, { cache: "no-store", signal: AbortSignal.timeout(8000) })
        : Promise.resolve(null),
      fetch(`${apiUrl}/products`, { cache: "no-store", signal: AbortSignal.timeout(10000) }),
    ]);
    try {
      if (reviewsResult.status === "fulfilled" && reviewsResult.value?.ok) {
        const payload = await reviewsResult.value.json();
        if (Array.isArray(payload)) reviews = payload;
      }
    } catch (error) {
      console.error("Could not read listing reviews:", error);
    }
    try {
      if (listingsResult.status === "fulfilled" && listingsResult.value.ok) {
        const payload = await listingsResult.value.json();
        if (Array.isArray(payload)) {
          ownerListings = payload
            .filter((item) => item && item.isClosedByAdmin !== true && String(item._id ?? item.id ?? "") !== productId)
            .filter((item) => product.ownerId ? item.ownerId === product.ownerId : item.ownerName === product.ownerName)
            .filter((item) => item.slug && item.title)
            .slice(0, 3)
            .map((item) => ({
              slug: item.slug,
              title: item.title,
              city: item.city || "",
              pricePerDay: item.pricePerDay,
              image: Array.isArray(item.images) ? item.images.find((image) => image?.url && !isVideo(image))?.url || null : null,
            }));
        }
      }
    } catch (error) {
      console.error("Could not read owner listings:", error);
    }

    return { props: { product, reviews, ownerListings, loadError: false } };
  } catch (error) {
    console.error("Could not load listing details:", error);
    res.statusCode = 503;
    return { props: { product: null, reviews: [], ownerListings: [], loadError: true } };
  }
}

export default function ListingDetails({ product, reviews, ownerListings, loadError }) {
  const [menuOpen, setMenuOpen] = useState(false);
  const [activeMedia, setActiveMedia] = useState(0);
  const modes = product ? availableModes(product) : [];
  const [selectedMode, setSelectedMode] = useState(modes[0]?.id ?? "day");
  const currentMode = modes.find((mode) => mode.id === selectedMode) ?? modes[0];
  const media = product && Array.isArray(product.images)
    ? product.images.filter((item) => item?.url)
    : [];
  const activeItem = media[activeMedia] ?? media[0];

  if (loadError) {
    return (
      <>
        <Head><title>Anunț indisponibil | PINLEND</title></Head>
        <SiteHeader menuOpen={menuOpen} setMenuOpen={setMenuOpen} />
        <main className="mx-auto min-h-screen max-w-4xl px-5 pb-24 pt-40 text-center md:px-20">
          <h1 className="font-display text-4xl font-extrabold">Nu am putut încărca anunțul.</h1>
          <p className="mt-5 text-[#434750]">Încearcă din nou peste câteva momente.</p>
          <Link className="mt-8 inline-block rounded-full bg-[#30578F] px-7 py-3 font-bold text-white" href="/archive">Înapoi la anunțuri</Link>
        </main>
      </>
    );
  }

  const description = product.description || `Descoperă ${product.title} pe PINLEND.`;
  const hasCoordinates = Number.isFinite(Number(product.latitude)) && Number.isFinite(Number(product.longitude))
    && product.latitude != null && product.longitude != null;
  const mapUrl = hasCoordinates ? makeMapUrl(Number(product.latitude), Number(product.longitude)) : null;
  const rating = Number(product.rating) || 0;
  const isAvailable = product.isAvailable !== false;
  const ownerInitial = String(product.ownerName || "P").trim().charAt(0).toUpperCase();

  return (
    <>
      <Head>
        <title>{product.title} | PINLEND</title>
        <meta name="description" content={description.slice(0, 160)} />
      </Head>
      <SiteHeader menuOpen={menuOpen} setMenuOpen={setMenuOpen} />

      <main className="mx-auto max-w-[1600px] px-5 pb-36 pt-28 md:px-12 lg:px-20 lg:pt-32">
        <nav aria-label="Navigare" className="mb-8 flex flex-wrap items-center gap-2 font-mono text-xs uppercase tracking-widest text-[#434750]">
          <Link className="hover:text-[#30578F]" href="/archive">Anunțuri</Link>
          <span>/</span>
          <span className="text-black">{product.category || "Detalii"}</span>
        </nav>

        <div className="grid items-start gap-5 lg:grid-cols-[minmax(0,1.25fr)_minmax(340px,0.75fr)] lg:gap-14">
          <div className="contents lg:block">
            <div className="relative order-1 aspect-[4/3] overflow-hidden rounded-[18px] bg-[#eeeeee]">
              {activeItem ? (
                isVideo(activeItem) ? (
                  <video className="h-full w-full object-contain" controls key={activeItem.url} playsInline src={activeItem.url} />
                ) : (
                  <img className="h-full w-full object-cover" src={activeItem.url} alt={activeItem.alt || product.title} />
                )
              ) : (
                <div className="flex h-full items-center justify-center text-[#434750]">Fără imagine</div>
              )}
              {media.length > 1 && (
                <>
                  <button aria-label="Imaginea precedentă" className="absolute left-3 top-1/2 flex h-10 w-10 -translate-y-1/2 items-center justify-center rounded-full bg-white/90 text-[#1B1B1B] shadow-sm" onClick={() => setActiveMedia((current) => (current - 1 + media.length) % media.length)} type="button"><span className="material-symbols-outlined">chevron_left</span></button>
                  <button aria-label="Imaginea următoare" className="absolute right-3 top-1/2 flex h-10 w-10 -translate-y-1/2 items-center justify-center rounded-full bg-white/90 text-[#1B1B1B] shadow-sm" onClick={() => setActiveMedia((current) => (current + 1) % media.length)} type="button"><span className="material-symbols-outlined">chevron_right</span></button>
                </>
              )}
              {media.length > 1 && (
                <div className="absolute bottom-4 right-4 rounded-full bg-white/90 px-4 py-2 text-xs font-bold text-[#434750] shadow-sm">
                  {activeMedia + 1} / {media.length}
                </div>
              )}
            </div>
            {media.length > 1 && (
              <div className="order-1 flex gap-3 overflow-x-auto pb-2 lg:mt-4" aria-label="Fotografiile anunțului">
                {media.map((item, index) => (
                  <button
                    aria-label={`Arată imaginea ${index + 1}`}
                    aria-pressed={activeMedia === index}
                    className={`relative h-20 w-24 shrink-0 overflow-hidden rounded-xl border-2 bg-[#eeeeee] transition-colors ${activeMedia === index ? "border-[#30578F]" : "border-transparent hover:border-[#8FABD4]"}`}
                    key={item.key || item.url}
                    onClick={() => setActiveMedia(index)}
                    type="button"
                  >
                    {isVideo(item) ? (
                      <span className="material-symbols-outlined flex h-full items-center justify-center text-[#30578F]">play_circle</span>
                    ) : (
                      <img className="h-full w-full object-cover" src={item.url} alt={item.alt || `${product.title} ${index + 1}`} />
                    )}
                  </button>
                ))}
              </div>
            )}

            <section className="order-3 rounded-[18px] bg-white p-6 shadow-sm md:p-8 lg:mt-10">
              <h2 className="text-2xl font-extrabold text-[#1B1B1B]">Descriere</h2>
              <p className="mt-4 whitespace-pre-line text-base leading-7 text-[#434750]">{description}</p>
            </section>

            <section className="order-3 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:mt-6">
              <Spec icon="category" label="Categorie" value={product.category || "—"} />
              <Spec icon="location_on" label="Locație" value={[product.address, product.city].filter(Boolean).join(", ") || "—"} />
              <Spec icon="account_balance_wallet" label="Garanție" value={formatRon(product.deposit)} />
              <Spec icon="schedule" label="Program" value={`${product.pickupTime || "10:00"} – ${product.returnTime || "18:00"}`} />
              <Spec icon="local_shipping" label="Disponibilitate" value={product.availabilityScope === "national" ? "Națională" : "Locală"} />
              {Number(product.stockQuantity) > 1 && <Spec icon="inventory_2" label="Stoc" value={`${product.stockQuantity} unități`} />}
            </section>

            <section className="order-3 rounded-[18px] bg-white p-6 shadow-sm md:p-8 lg:mt-10">
              <h2 className="text-2xl font-extrabold text-[#1B1B1B]">Locație</h2>
              <p className="mt-2 text-[#434750]">{[product.address, product.city].filter(Boolean).join(", ") || "Locația nu este specificată."}</p>
              {mapUrl && (
                <div className="mt-5 overflow-hidden rounded-[14px]">
                  <iframe className="h-64 w-full border-0" loading="lazy" referrerPolicy="no-referrer" src={mapUrl} title={`Locația anunțului ${product.title}`} />
                </div>
              )}
              {hasCoordinates && (
                <a className="mt-4 inline-flex items-center gap-2 font-bold text-[#30578F]" href={`https://www.google.com/maps/search/?api=1&query=${product.latitude},${product.longitude}`} rel="noopener noreferrer" target="_blank">
                  Vezi indicațiile <span className="material-symbols-outlined text-lg">open_in_new</span>
                </a>
              )}
            </section>

            <Reviews reviews={reviews} />
            {ownerListings.length > 0 && <OwnerListings listings={ownerListings} />}
          </div>

          <aside className="contents lg:sticky lg:top-28 lg:block">
            <div className="order-2 rounded-[18px] bg-white p-6 shadow-sm md:p-8">
              <p className="font-mono text-xs uppercase tracking-widest text-[#30578F]">{product.category || "Anunț PINLEND"}</p>
              <h1 className="mt-4 font-display text-4xl font-extrabold leading-tight text-[#1B1B1B] md:text-5xl">{product.title}</h1>
              <div className="mt-4 flex flex-wrap items-center gap-3 text-sm text-[#434750]">
                {rating > 0 && <span className="inline-flex items-center gap-1 font-bold text-[#1B1B1B]"><span className="material-symbols-outlined text-amber-500">star</span>{rating.toFixed(1)} / 5</span>}
                {product.city && <span className="inline-flex items-center gap-1"><span className="material-symbols-outlined text-lg">location_on</span>{product.city}</span>}
              </div>
              <div className="mt-6 flex flex-wrap gap-2">
                <span className={`rounded-full px-3 py-2 text-xs font-bold ${product.isAvailable === false ? "bg-neutral-100 text-[#434750]" : "bg-[#30578F]/10 text-[#30578F]"}`}>
                  {isAvailable ? "Disponibil acum" : "Momentan indisponibil"}
                </span>
                {product.availabilityScope === "national" && <span className="rounded-full bg-[#446085]/10 px-3 py-2 text-xs font-bold text-[#446085]">Disponibil în toată țara</span>}
              </div>

              {modes.length > 0 && (
                <>
                  <div className="mt-8 inline-flex flex-wrap gap-1 rounded-full bg-[#F3F3F3] p-1" aria-label="Perioada de închiriere">
                    {modes.map((mode) => (
                      <button
                        aria-pressed={selectedMode === mode.id}
                        className={`rounded-full px-5 py-2 text-sm font-bold transition-colors ${selectedMode === mode.id ? "bg-[#30578F] text-white" : "text-[#434750] hover:bg-white"}`}
                        key={mode.id}
                        onClick={() => setSelectedMode(mode.id)}
                        type="button"
                      >
                        {mode.label}
                      </button>
                    ))}
                  </div>
                  <p className="mt-6 text-3xl font-extrabold text-[#1B1B1B]">{formatRon(currentMode.price)} <span className="text-base font-semibold text-[#434750]">{currentMode.suffix}</span></p>
                </>
              )}
              <Link className="mt-7 flex min-h-12 items-center justify-center gap-2 rounded-full bg-[#30578F] px-6 py-3 text-center font-bold text-white transition-colors hover:bg-[#23436F]" href="/download">
                {isAvailable ? "Închiriază în aplicație" : "Vezi disponibilitatea în aplicație"} <span className="material-symbols-outlined text-lg">arrow_forward</span>
              </Link>
              {product.viewingsEnabled && (
                <p className="mt-4 rounded-xl bg-[#F3F3F3] p-4 text-sm leading-6 text-[#434750]">
                  Vizionare disponibilă în aplicație{Number(product.viewingPriceRon) > 0 ? ` pentru ${formatRon(product.viewingPriceRon)}` : " gratuit"}.
                </p>
              )}
            </div>

            <div className="order-4 rounded-[18px] bg-white p-6 shadow-sm md:p-8 lg:mt-6">
              <p className="font-mono text-xs uppercase tracking-widest text-[#434750]">Proprietar</p>
              <div className="mt-5 flex items-center gap-4">
                <div className="flex h-16 w-16 shrink-0 items-center justify-center overflow-hidden rounded-full bg-[#D3E3FF] text-2xl font-extrabold text-[#30578F]">
                  {product.ownerAvatarUrl ? <img className="h-full w-full object-cover" src={product.ownerAvatarUrl} alt={product.ownerName || "Proprietar"} /> : ownerInitial}
                </div>
                <div className="min-w-0">
                  <h2 className="truncate text-xl font-extrabold">{product.ownerName || "Proprietar PINLEND"}</h2>
                  <p className="mt-1 text-sm text-[#434750]">{Number(product.ownerRentalCount) || 0} închirieri</p>
                </div>
              </div>
              <Link className="mt-6 flex min-h-12 items-center justify-center rounded-xl border border-[#30578F] px-5 py-3 text-center font-bold text-[#30578F] hover:bg-[#30578F]/5" href="/download">Trimite mesaj în aplicație</Link>
              {ownerListings.length > 0 && <a className="mt-4 block text-center text-sm font-bold text-[#30578F]" href="#owner-listings">Vezi și alte anunțuri ale proprietarului</a>}
            </div>

            {product.categorySlug === "imobiliare" && (
              <div className="order-5 rounded-[18px] bg-white p-6 shadow-sm md:p-8 lg:mt-6">
                <div className="flex items-center gap-2 text-lg font-extrabold"><span className="material-symbols-outlined text-[#30578F]">groups</span> Cauți un coleg de apartament?</div>
                <p className="mt-3 text-sm leading-6 text-[#434750]">Poți publica o cerere și poți programa o vizionare din aplicația PINLEND.</p>
                <Link className="mt-5 inline-flex rounded-full bg-[#30578F] px-5 py-3 text-sm font-bold text-white" href="/download">Deschide aplicația</Link>
              </div>
            )}

            <div className="order-6 rounded-xl bg-[#446085]/10 p-5 text-sm leading-6 text-[#446085] lg:mt-6">
              <div className="flex items-center gap-2 font-extrabold"><span className="material-symbols-outlined">security</span> PINLEND Protect</div>
              <p className="mt-2">Detaliile închirierii și garanția sunt gestionate în aplicație.</p>
            </div>
          </aside>
        </div>
      </main>
      <footer className="bg-black px-5 py-12 text-white md:px-20">
        <div className="mx-auto flex max-w-[1440px] flex-col justify-between gap-6 border-b border-white/10 pb-8 md:flex-row md:items-center">
          <span className="font-display text-2xl font-bold">PINLEND</span>
          <nav className="flex flex-wrap gap-5 text-sm text-white/70">
            <Link className="hover:text-white" href="/archive">Anunțuri</Link>
            <Link className="hover:text-white" href="/download">Aplicația mobilă</Link>
            <Link className="hover:text-white" href="/support">Suport</Link>
          </nav>
        </div>
        <p className="mx-auto mt-8 max-w-[1440px] text-xs text-white/50">© {new Date().getFullYear()} PINLEND</p>
      </footer>
      <div className="fixed inset-x-0 bottom-0 z-40 flex items-center gap-4 border-t border-black/10 bg-white px-5 py-3 shadow-[0_-4px_16px_rgba(0,0,0,0.08)] lg:hidden">
        <div className="min-w-0 flex-1">
          {currentMode ? <><p className="truncate text-lg font-extrabold">{formatRon(currentMode.price)}</p><p className="text-xs text-[#434750]">{currentMode.suffix}</p></> : <p className="font-bold">Vezi anunțul în aplicație</p>}
        </div>
        <Link className="shrink-0 rounded-full bg-[#30578F] px-5 py-3 text-sm font-bold text-white" href="/download">{isAvailable ? "Închiriază" : "Vezi în aplicație"}</Link>
      </div>
    </>
  );
}

function isVideo(item) {
  return item?.type === "video" || String(item?.contentType || "").startsWith("video/");
}

function makeMapUrl(latitude, longitude) {
  const delta = 0.012;
  const bbox = [longitude - delta, latitude - delta, longitude + delta, latitude + delta].join(",");
  return `https://www.openstreetmap.org/export/embed.html?bbox=${encodeURIComponent(bbox)}&layer=mapnik&marker=${latitude}%2C${longitude}`;
}

function Spec({ icon, label, value }) {
  return (
    <div className="min-w-0 rounded-xl bg-white p-4 shadow-sm">
      <span className="material-symbols-outlined text-[#30578F]">{icon}</span>
      <p className="mt-2 text-xs text-[#434750]">{label}</p>
      <p className="mt-1 break-words font-bold text-[#1B1B1B]">{value}</p>
    </div>
  );
}

function Reviews({ reviews }) {
  return (
    <section className="order-3 lg:mt-10">
      <h2 className="text-2xl font-extrabold text-[#1B1B1B]">Recenzii <span className="text-lg font-semibold text-[#434750]">({reviews.length})</span></h2>
      {reviews.length === 0 ? (
        <p className="mt-4 rounded-xl bg-white p-6 text-[#434750] shadow-sm">Acest anunț nu are încă recenzii.</p>
      ) : (
        <div className="mt-5 grid gap-4 md:grid-cols-2">
          {reviews.map((review, index) => {
            const name = review.reviewer?.fullName || "Utilizator";
            const rating = Math.max(0, Math.min(5, Number(review.rating) || 0));
            return (
              <article className="rounded-xl bg-white p-5 shadow-sm" key={review._id || review.id || index}>
                <div className="flex items-center gap-3">
                  <div className="flex h-11 w-11 shrink-0 items-center justify-center overflow-hidden rounded-full bg-[#E7F0FD] font-extrabold text-[#30578F]">
                    {review.reviewer?.avatarUrl ? <img className="h-full w-full object-cover" src={review.reviewer.avatarUrl} alt={name} /> : name.charAt(0).toUpperCase()}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-extrabold">{name}</p>
                    {review.createdAt && <p className="text-xs text-[#434750]">{new Date(review.createdAt).toLocaleDateString("ro-RO", { timeZone: "UTC" })}</p>}
                  </div>
                  <span aria-label={`${rating} din 5 stele`} className="shrink-0 font-bold text-amber-500">★ {rating}/5</span>
                </div>
                {review.comment && <p className="mt-4 whitespace-pre-line leading-6 text-[#434750]">{review.comment}</p>}
              </article>
            );
          })}
        </div>
      )}
    </section>
  );
}

function OwnerListings({ listings }) {
  return (
    <section className="order-3 scroll-mt-28 lg:mt-10" id="owner-listings">
      <h2 className="text-2xl font-extrabold text-[#1B1B1B]">Alte anunțuri ale proprietarului</h2>
      <div className="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {listings.map((item) => (
          <Link className="overflow-hidden rounded-xl bg-white shadow-sm transition-transform hover:-translate-y-1" href={`/anunt/${encodeURIComponent(item.slug)}`} key={item.slug}>
            <div className="aspect-[4/3] bg-[#eeeeee]">
              {item.image ? <img className="h-full w-full object-cover" src={item.image} alt={item.title} /> : <div className="flex h-full items-center justify-center text-sm text-[#434750]">Fără imagine</div>}
            </div>
            <div className="p-4">
              <h3 className="font-bold text-[#1B1B1B]">{item.title}</h3>
              <p className="mt-2 text-sm text-[#434750]">{item.city} · {formatRon(item.pricePerDay)} / zi</p>
            </div>
          </Link>
        ))}
      </div>
    </section>
  );
}

function SiteHeader({ menuOpen, setMenuOpen }) {
  return (
    <>
      <header className="fixed left-0 right-0 top-0 z-50 bg-[#f9f9f9]/90 backdrop-blur-md">
        <div className="flex h-20 items-center justify-between px-5 md:px-20">
          <BrandLogo />
          <nav className="flex items-center gap-6 font-mono text-xs uppercase tracking-widest md:gap-14">
            <Link className="hidden hover:text-[#30578F] sm:inline" href="/archive">Anunțuri</Link>
            <button className="flex items-center gap-3" onClick={() => setMenuOpen(true)} type="button"><span className="h-px w-8 bg-black" /> Meniu</button>
            <Link aria-label="Contul meu" className="flex h-8 w-8 items-center justify-center rounded-full bg-black text-white" href="/account"><span className="material-symbols-outlined text-[18px]">person</span></Link>
          </nav>
        </div>
      </header>
      <div aria-hidden={!menuOpen} className={`mega-menu-overlay fixed inset-0 z-[60] flex flex-col justify-center bg-black px-5 md:px-20 ${menuOpen ? "mega-menu-open" : ""}`}>
        <button className="absolute right-6 top-8 font-mono text-xs uppercase tracking-widest text-white" onClick={() => setMenuOpen(false)} type="button">Închide ✕</button>
        <nav className="flex flex-col gap-6">
          {[["Acasă", "/"], ["Funcționalități", "/features"], ["Anunțuri", "/archive"], ["Descarcă", "/download"]].map(([label, href]) => (
            <Link className="font-display text-5xl font-bold text-white transition-colors hover:text-[#8FABD4] md:text-7xl" href={href} key={href} onClick={() => setMenuOpen(false)}>{label}</Link>
          ))}
        </nav>
      </div>
    </>
  );
}
