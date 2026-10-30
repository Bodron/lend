import Head from "next/head";
import { useToastNotice } from "../lib/useToastNotice";
import FormSelect from "../components/FormSelect";
import { Input } from "../components/ui/input";
import { RentalDateField } from "../components/RentalPeriodFields";
import { Textarea } from "../components/ui/textarea";
import Link from "next/link";
import { useEffect, useState } from "react";
import { useRouter } from "next/router";
import AppHeader from "../components/AppHeader";
import { accountRequest, requireLogin } from "../lib/accountRequest";
import { getBackendApiUrl } from "../lib/backendApi";
import { useToastError } from "../lib/useToastError";
import { useConfirmAction } from "../components/ConfirmActionProvider";

const idOf = (item) => String(item?._id || item?.id || "");
const initialForm = { productId: "", title: "", city: "", area: "", budgetPerMonth: "", moveInDate: "", description: "", preferences: "" };

export async function getServerSideProps({ query }) {
  const filters = new URLSearchParams();
  for (const key of ["q", "minBudget", "maxBudget", "lat", "lng", "radiusKm"]) {
    if (typeof query[key] === "string" && query[key].length < 120) filters.set(key, query[key]);
  }
  try {
    const response = await fetch(`${getBackendApiUrl()}/roommate-posts?${filters}`, { cache: "no-store", signal: AbortSignal.timeout(10000) });
    return { props: { posts: response.ok ? await response.json() : [], filters: Object.fromEntries(filters) } };
  } catch { return { props: { posts: [], filters: Object.fromEntries(filters) } }; }
}

export default function Roommates({ posts, filters }) {
  const confirmAction = useConfirmAction();
  const router = useRouter();
  const en = router.locale === "en";
  const [user, setUser] = useState(null);
  const [mine, setMine] = useState({ posts: [], interests: [] });
  const [listings, setListings] = useState([]);
  const [form, setForm] = useState(initialForm);
  const [message, setMessage] = useState({});
  const [showCreate, setShowCreate] = useState(false);
  const [position, setPosition] = useState({ lat: filters.lat || "", lng: filters.lng || "" });
  const [busy, setBusy] = useState("");
  const [, setError] = useToastError();
  const setNotice = useToastNotice();
  useEffect(() => {
    Promise.all([accountRequest("me"), accountRequest("roommateMine"), accountRequest("listings")])
      .then(([profile, own, products]) => { setUser(profile); setMine(own); setListings(products.filter((item) => item.categorySlug === "imobiliare")); })
      .catch((cause) => { if (cause.status !== 401) setError(cause.message); });
  }, [setError]);

  async function create(event) {
    event.preventDefault(); setBusy("create"); setError("");
    try {
      const payload = { ...form, budgetPerMonth: Number(form.budgetPerMonth), preferences: form.preferences.split(",").map((item) => item.trim()).filter(Boolean) };
      if (!payload.productId) delete payload.productId;
      await accountRequest("roommateCreate", { method: "POST", body: JSON.stringify(payload) });
      setNotice(en ? "Roommate request published." : "Anunțul pentru coleg a fost publicat."); setShowCreate(false); setForm(initialForm);
      setMine(await accountRequest("roommateMine"));
      router.reload();
    } catch (cause) { if (!requireLogin(cause, "/colegi")) setError(cause.message); }
    finally { setBusy(""); }
  }
  async function interest(post) {
    setBusy(idOf(post)); setError("");
    try {
      const result = await accountRequest("roommateInterest", { method: "POST", body: JSON.stringify({ id: idOf(post), message: message[idOf(post)]?.trim() || undefined }) });
      setNotice(en ? "Message sent." : "Mesajul a fost trimis.");
      if (result.productId && (result.interest?._id || result.interestId)) {
        router.push(`/mesaje?productId=${encodeURIComponent(result.productId)}&roommateInterestId=${encodeURIComponent(result.interest?._id || result.interestId)}`);
      }
    } catch (cause) { if (!requireLogin(cause, "/colegi")) setError(cause.message); }
    finally { setBusy(""); }
  }
  async function close(post) {
    if (!await confirmAction({
      title: en ? "Close this request?" : "Închizi acest anunț?",
      description: en ? "The roommate request will no longer be active." : "Cererea pentru coleg de apartament nu va mai fi activă.",
      confirmLabel: en ? "Close request" : "Închide anunțul",
      destructive: true,
    })) return;
    try { await accountRequest("roommateClose", { method: "PATCH", body: JSON.stringify({ id: idOf(post) }) }); setMine(await accountRequest("roommateMine")); router.reload(); }
    catch (cause) { setError(cause.message); }
  }
  const update = (key, value) => setForm((current) => ({ ...current, [key]: value }));
  function useLocation() {
    if (!navigator.geolocation) { setError(en ? "Your browser does not support location access." : "Browserul nu oferă acces la locație."); return; }
    navigator.geolocation.getCurrentPosition(({ coords }) => setPosition({ lat: String(coords.latitude), lng: String(coords.longitude) }), () => setError(en ? "We could not get your location." : "Nu am putut obține locația."), { timeout: 10000 });
  }

  return <>
    <Head><title>{en ? "Find a roommate | PINLEND" : "Caută coleg de apartament | PINLEND"}</title></Head>
    <AppHeader />
    <main className="mx-auto max-w-7xl px-5 py-12 md:px-8"><p className="font-mono text-xs uppercase tracking-widest text-[#30578F]">{en ? "Homes" : "Locuințe"}</p><div className="mt-3 flex flex-wrap items-end justify-between gap-4"><div><h1 className="font-display text-4xl font-extrabold">{en ? "Find a roommate" : "Caută coleg"}</h1><p className="mt-3 text-[#626977]">{en ? "Find people looking to share a home." : "Descoperă persoane care caută să împartă o locuință."}</p></div><button className="account-button" onClick={() => { if (!user) router.push(`/account?returnTo=${encodeURIComponent("/colegi")}`); else setShowCreate(!showCreate); }} type="button">{showCreate ? (en ? "Close form" : "Închide formularul") : (en ? "+ Post a request" : "+ Publică o cerere")}</button></div>
      
      <form className="account-card mt-8 flex flex-wrap items-end gap-3" method="GET"><label className="min-w-48 flex-1 text-sm font-bold">{en ? "Search" : "Caută"}<Input className="account-input" defaultValue={filters.q || ""} name="q" placeholder={en ? "City, area, preferences" : "Oraș, zonă, preferințe"} /></label><label className="text-sm font-bold">{en ? "Minimum budget" : "Buget minim"}<Input className="account-input w-36" defaultValue={filters.minBudget || ""} min="0" name="minBudget" type="number" /></label><label className="text-sm font-bold">{en ? "Maximum budget" : "Buget maxim"}<Input className="account-input w-36" defaultValue={filters.maxBudget || ""} min="0" name="maxBudget" type="number" /></label><input name="lat" type="hidden" value={position.lat} readOnly /><input name="lng" type="hidden" value={position.lng} readOnly /><label className="text-sm font-bold">{en ? "Radius (km)" : "Rază (km)"}<Input className="account-input w-32" defaultValue={filters.radiusKm || "25"} min="1" name="radiusKm" type="number" /></label><button className="account-button-light" onClick={useLocation} type="button">{position.lat ? (en ? "Location selected" : "Locație selectată") : (en ? "Use my location" : "Folosește locația")}</button><button className="account-button" type="submit">{en ? "Search" : "Caută"}</button></form>
      {showCreate && <form className="account-card mt-6" onSubmit={create}><h2 className="text-xl font-extrabold">{en ? "New request" : "Cerere nouă"}</h2><div className="mt-5 grid gap-4 sm:grid-cols-2"><Field label={en ? "Title" : "Titlu"}><Input className="account-input" required value={form.title} onChange={(e) => update("title", e.target.value)} /></Field><Field label={en ? "City" : "Oraș"}><Input className="account-input" required value={form.city} onChange={(e) => update("city", e.target.value)} /></Field><Field label={en ? "Area" : "Zonă"}><Input className="account-input" value={form.area} onChange={(e) => update("area", e.target.value)} /></Field><Field label={en ? "Monthly budget (RON)" : "Buget lunar (RON)"}><Input className="account-input" min="1" required type="number" value={form.budgetPerMonth} onChange={(e) => update("budgetPerMonth", e.target.value)} /></Field><RentalDateField label={en ? "Move-in date" : "Data mutării"} onChange={(value) => update("moveInDate", value)} value={form.moveInDate} /><Field label={en ? "Link a listing (optional)" : "Leagă de un anunț (opțional)"}><FormSelect className="account-input" value={form.productId} onChange={(e) => update("productId", e.target.value)}><option value="">{en ? "No listing" : "Fără anunț"}</option>{listings.map((item) => <option key={idOf(item)} value={idOf(item)}>{item.title}</option>)}</FormSelect></Field><div className="sm:col-span-2"><Field label={en ? "Description" : "Descriere"}><Textarea className="account-input min-h-24" required value={form.description} onChange={(e) => update("description", e.target.value)} /></Field></div><div className="sm:col-span-2"><Field label={en ? "Preferences, separated by commas" : "Preferințe, separate prin virgulă"}><Input className="account-input" value={form.preferences} onChange={(e) => update("preferences", e.target.value)} /></Field></div></div><button className="account-button mt-5" disabled={busy === "create"} type="submit">{en ? "Publish" : "Publică"}</button></form>}
      {mine.posts.length > 0 && <section className="mt-8"><h2 className="text-xl font-extrabold">{en ? "My requests" : "Cererile mele"}</h2><div className="mt-3 flex flex-wrap gap-3">{mine.posts.map((post) => <div className="account-card flex items-center gap-3" key={idOf(post)}><span>{post.title} · {post.status === "open" ? (en ? "Open" : "Deschis") : (en ? "Closed" : "Închis")}</span>{post.status === "open" && <button className="text-sm font-bold text-red-700" onClick={() => close(post)} type="button">{en ? "Close" : "Închide"}</button>}</div>)}</div></section>}
      <section className="mt-9 grid gap-5 md:grid-cols-2">{posts.map((post) => <article className="account-card" key={idOf(post)}><p className="font-mono text-xs uppercase tracking-widest text-[#30578F]">{post.city}{post.area && ` · ${post.area}`}</p><h2 className="mt-3 text-2xl font-extrabold">{post.title}</h2><p className="mt-2 text-sm text-[#626977]">{post.authorName} · {post.budgetPerMonth} RON/{en ? "month" : "lună"}{post.moveInDate && ` · ${en ? "From" : "Din"} ${post.moveInDate}`}</p><p className="mt-4 whitespace-pre-line text-sm leading-6">{post.description}</p>{post.preferences?.length > 0 && <p className="mt-3 text-xs text-[#626977]">{en ? "Preferences" : "Preferințe"}: {post.preferences.join(", ")}</p>}{post.product?.slug && <Link className="mt-4 block font-bold text-[#30578F]" href={`/anunt/${encodeURIComponent(post.product.slug)}`}>{en ? "View home" : "Vezi locuința"} →</Link>}{idOf(post) && post.authorId !== (user?.id || user?._id) && <div className="mt-5 flex gap-2"><Input aria-label={`Mesaj către ${post.authorName}`} className="account-input mt-0" onChange={(e) => setMessage({ ...message, [idOf(post)]: e.target.value })} placeholder={en ? "Write a message" : "Scrie un mesaj"} value={message[idOf(post)] || ""} /><button className="account-button" disabled={busy === idOf(post)} onClick={() => interest(post)} type="button">{en ? "Send" : "Trimite"}</button></div>}</article>)}{posts.length === 0 && <p className="text-[#626977]">{en ? "No requests match these filters." : "Nu există cereri pentru filtrele alese."}</p>}</section>
    </main>
  </>;
}

function Field({ label, children }) { return <label className="block text-sm font-bold">{label}{children}</label>; }
