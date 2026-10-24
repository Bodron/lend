import Head from "next/head";
import { useToastNotice } from "../lib/useToastNotice";
import FormSelect from "../components/FormSelect";
import { Input } from "../components/ui/input";
import Link from "next/link";
import { useCallback, useEffect, useMemo, useState } from "react";
import AppHeader from "../components/AppHeader";
import BrandLoader from "../components/BrandLoader";
import { useToastError } from "../lib/useToastError";
import { useConfirmAction } from "../components/ConfirmActionProvider";
import { useAccountProfile } from "../components/AccountProfileProvider";
import UserAvatar from "../components/UserAvatar";
import { CircleCheck } from "lucide-react";

const money = new Intl.NumberFormat("ro-RO", { maximumFractionDigits: 2 });
const formatRon = (value) => `${money.format(Number(value) || 0)} RON`;
const accountSections = [
  { id: "overview", label: "Prezentare", icon: "dashboard" },
  { id: "listings", label: "Anunțurile mele", icon: "inventory_2" },
  { id: "rentals", label: "Închirieri", icon: "handshake" },
  { id: "earnings", label: "Încasări", icon: "account_balance_wallet" },
  { id: "profile", label: "Profil", icon: "person" },
];
const historicalStatuses = new Set(["completed", "cancelled", "rejected"]);
const formatDate = (value) => value ? new Intl.DateTimeFormat("ro-RO", { day: "numeric", month: "short", year: "numeric" }).format(new Date(value)) : "—";

async function accountRequest(action, options = {}) {
  let response;
  try {
    response = await fetch(`/api/account/${action}`, {
      credentials: "same-origin",
      cache: "no-store",
      ...options,
      headers: { "Content-Type": "application/json", ...options.headers },
    });
  } catch {
    throw new Error("Nu putem contacta site-ul acum. Verifică conexiunea și încearcă din nou.");
  }
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message = Array.isArray(payload.message) ? payload.message.join(" ") : payload.message;
    const error = new Error(message || "Operațiunea nu a reușit.");
    error.status = response.status;
    throw error;
  }
  return payload;
}

function payoutFigures(orders) {
  const now = Date.now();
  return orders.reduce((totals, order) => {
    const amount = Number(order.ownerEarnings) || 0;
    if (order.status === "completed" && order.paymentStatus === "captured") {
      totals.earned += amount;
      if (order.payoutStatus === "paid_out") totals.paid += amount;
      if (
        order.payoutStatus === "eligible" ||
        (order.payoutStatus === "held_until_return" && order.payoutEligibleAt && new Date(order.payoutEligibleAt).getTime() <= now)
      ) totals.available += amount;
    }
    return totals;
  }, { earned: 0, available: 0, paid: 0 });
}

function validStripeUrl(value) {
  try {
    const url = new URL(value);
    return url.protocol === "https:" && (url.hostname === "stripe.com" || url.hostname.endsWith(".stripe.com"));
  } catch {
    return false;
  }
}

export default function Account() {
  const confirmAction = useConfirmAction();
  const { setProfile } = useAccountProfile();
  const [loading, setLoading] = useState(true);
  const [user, setUser] = useState(null);
  const [orders, setOrders] = useState([]);
  const [renterOrders, setRenterOrders] = useState([]);
  const [listings, setListings] = useState([]);
  const [activeSection, setActiveSection] = useState("overview");
  const [rentalPerspective, setRentalPerspective] = useState("renting");
  const [rentalHistory, setRentalHistory] = useState(false);
  const [identity, setIdentity] = useState(null);
  const [connect, setConnect] = useState(null);
  const [, setSectionError] = useToastError();
  const [, setError] = useToastError();
  const setNotice = useToastNotice();
  const [busy, setBusy] = useState("");
  const [authMode, setAuthMode] = useState("login");
  const [form, setForm] = useState({ fullName: "", email: "", phone: "", password: "" });
  const [credentialsEditable, setCredentialsEditable] = useState(false);
  const [sessionCheckError, setSessionCheckError] = useToastError();
  const [city, setCity] = useState("");
  const [coordinates, setCoordinates] = useState(null);
  const [businessType, setBusinessType] = useState("individual");

  const refresh = useCallback(async () => {
    setSectionError("");
    let profile;
    try {
      profile = await accountRequest("me");
    } catch (cause) {
      if (cause.status === 401) { setUser(null); setProfile(null); }
      throw cause;
    }
    setUser(profile);
    setProfile(profile);
    setSessionCheckError("");
    setCity(profile.city || "");
    setCoordinates(profile.latitude != null && profile.longitude != null
      ? { latitude: Number(profile.latitude), longitude: Number(profile.longitude) }
      : null);

    const results = await Promise.allSettled([
      accountRequest("orders"),
      accountRequest("renterOrders"),
      accountRequest("listings"),
      accountRequest("identityStatus"),
      accountRequest("connectStatus"),
    ]);
    if (results[0].status === "fulfilled" && Array.isArray(results[0].value)) setOrders(results[0].value);
    if (results[1].status === "fulfilled" && Array.isArray(results[1].value)) setRenterOrders(results[1].value);
    if (results[2].status === "fulfilled" && Array.isArray(results[2].value)) setListings(results[2].value);
    if (results[3].status === "fulfilled") setIdentity(results[3].value);
    if (results[4].status === "fulfilled") {
      setConnect(results[4].value);
      if (Array.isArray(results[4].value?.errors) && results[4].value.errors.length) setSectionError(results[4].value.errors.join(" "));
    }
    if (results.some((result) => result.status === "rejected")) {
      setSectionError("Unele date nu au putut fi încărcate. Apasă Actualizează pentru a încerca din nou.");
    }
  }, [setProfile, setSectionError, setSessionCheckError]);

  useEffect(() => {
    const requestedSection = new URLSearchParams(window.location.search).get("section");
    if (accountSections.some((section) => section.id === requestedSection)) {
      Promise.resolve().then(() => { setActiveSection(requestedSection); if (requestedSection === "rentals") setRentalPerspective("renting"); });
    }
    const stripeResult = new URLSearchParams(window.location.search).get("stripe");
    if (stripeResult === "return") Promise.resolve().then(() => setNotice("Ai revenit de la Stripe. Starea contului se actualizează.", "info"));
    if (stripeResult === "refresh") Promise.resolve().then(() => setNotice("Linkul Stripe a expirat. Poți relua configurarea de aici.", "warning"));
    Promise.resolve().then(refresh).catch((cause) => {
      if (cause.status !== 401) setSessionCheckError("Nu putem verifica sesiunea acum. Încearcă din nou.");
    }).finally(() => setLoading(false));
    const onFocus = () => {
      if (document.visibilityState === "visible") {
        refresh().catch(() => {});
      }
    };
    document.addEventListener("visibilitychange", onFocus);
    return () => document.removeEventListener("visibilitychange", onFocus);
  }, [refresh, setNotice, setSessionCheckError]);

  const figures = useMemo(() => payoutFigures(orders), [orders]);
  const connectReady = Boolean(connect?.connected && connect?.payoutsEnabled && connect?.detailsSubmitted);
  const eligibleOrders = orders.filter((order) => order.status === "completed" && order.paymentStatus === "captured");
  const visibleRentals = (rentalPerspective === "renting" ? renterOrders : orders)
    .filter((order) => historicalStatuses.has(order.status) === rentalHistory);

  async function submitAuth(event) {
    event.preventDefault();
    setError("");
    setNotice("");
    setBusy("auth");
    try {
      await accountRequest(authMode, {
        method: "POST",
        body: JSON.stringify(authMode === "login"
          ? { email: form.email.trim(), password: form.password }
          : { fullName: form.fullName.trim(), email: form.email.trim(), phone: form.phone.trim(), password: form.password }),
      });
      setForm((previous) => ({ ...previous, password: "" }));
      await refresh();
      const returnTo = new URLSearchParams(window.location.search).get("returnTo");
      if (returnTo?.startsWith("/") && !returnTo.startsWith("//") && !returnTo.includes("\\") && new URL(returnTo, window.location.origin).origin === window.location.origin) {
        window.location.assign(returnTo);
        return;
      }
    } catch (cause) {
      setError(cause.message);
    } finally {
      setBusy("");
    }
  }

  async function retrySession() {
    setLoading(true);
    setSessionCheckError("");
    try {
      await refresh();
    } catch (cause) {
      if (cause.status !== 401) setSessionCheckError("Nu putem verifica sesiunea acum. Încearcă din nou.");
    } finally { setLoading(false); }
  }

  async function logout() {
    setBusy("logout");
    try {
      await accountRequest("logout", { method: "POST" });
      setUser(null);
      setProfile(null);
      setOrders([]);
      setRenterOrders([]);
      setListings([]);
      setIdentity(null);
      setConnect(null);
      setError("");
      setNotice("");
      setForm({ fullName: "", email: "", phone: "", password: "" });
      setCredentialsEditable(false);
      setSessionCheckError("");
    } catch (cause) {
      setError(cause.message);
    } finally {
      setBusy("");
    }
  }

  async function decideRental(orderId, action) {
    const accepting = action === "rentalAccept";
    if (!await confirmAction({
      title: accepting ? "Accepți închirierea?" : "Refuzi închirierea?",
      description: accepting ? "Plata autorizată va fi capturată." : "Autorizarea plății va fi eliberată.",
      confirmLabel: accepting ? "Acceptă închirierea" : "Refuză închirierea",
      destructive: !accepting,
    })) return;
    setBusy(`rental-${orderId}`);
    setError("");
    try {
      await accountRequest(action, { method: "PATCH", body: JSON.stringify({ orderId }) });
      await refresh();
      setNotice(action === "rentalAccept" ? "Închirierea a fost confirmată." : "Închirierea a fost refuzată.");
    } catch (cause) { setError(cause.message); }
    finally { setBusy(""); }
  }

  async function saveLocation(event) {
    event.preventDefault();
    setError("");
    setNotice("");
    if (!city.trim()) return setError("Introdu orașul înainte de a salva locația.");
    setBusy("location");
    try {
      const profile = await accountRequest("location", {
        method: "PATCH",
        body: JSON.stringify({ city: city.trim(), latitude: coordinates?.latitude ?? null, longitude: coordinates?.longitude ?? null }),
      });
      setUser(profile);
      setProfile(profile);
      setNotice("Locația a fost salvată.");
    } catch (cause) {
      setError(cause.message);
    } finally {
      setBusy("");
    }
  }

  async function uploadAvatar(event) {
    const input = event.currentTarget;
    const file = input.files?.[0];
    if (!file) return;
    if (!["image/jpeg", "image/png", "image/webp"].includes(file.type) || file.size > 10_000_000) {
      setError("Alege o imagine JPG, PNG sau WebP de maximum 10 MB.");
      input.value = "";
      return;
    }
    setBusy("avatar");
    setError("");
    try {
      const upload = await accountRequest("uploadUrl", {
        method: "POST",
        body: JSON.stringify({ fileName: file.name, contentType: file.type, size: file.size }),
      });
      const response = await fetch(upload.uploadUrl, {
        method: "PUT",
        headers: upload.headers || { "Content-Type": file.type },
        body: file,
      });
      if (!response.ok) throw new Error("Nu am putut încărca fotografia.");
      const profile = await accountRequest("avatar", {
        method: "PATCH",
        body: JSON.stringify({ avatarUrl: upload.readableUrl, avatarKey: upload.key }),
      });
      setUser(profile);
      setProfile(profile);
      setNotice("Fotografia de profil a fost actualizată.");
    } catch (cause) {
      setError(cause.message);
    } finally {
      setBusy("");
      input.value = "";
    }
  }

  function useMyLocation() {
    setError("");
    if (!navigator.geolocation) return setError("Browserul nu oferă acces la locație.");
    setBusy("geo");
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        setCoordinates({ latitude: coords.latitude, longitude: coords.longitude });
        setNotice("Coordonatele au fost preluate. Introdu orașul și salvează locația.", "info");
        setBusy("");
      },
      () => { setError("Nu am putut obține locația. O poți introduce manual."); setBusy(""); },
      { enableHighAccuracy: false, timeout: 10000 },
    );
  }

  async function openStripe(action, body) {
    setError("");
    setNotice("");
    setBusy(action);
    const tab = window.open("about:blank", "_blank");
    if (tab) tab.opener = null;
    try {
      const result = await accountRequest(action, { method: "POST", body: JSON.stringify(body || {}) });
      if (result.verified) {
        if (tab) tab.close();
        setNotice("Identitatea este verificată.");
        await refresh();
      } else if (result.processing) {
        if (tab) tab.close();
        setNotice("Stripe verifică documentul. Actualizează starea peste câteva momente.", "info");
      } else if (result.url && validStripeUrl(result.url)) {
        if (tab) tab.location.replace(result.url);
        else window.location.assign(result.url);
        setNotice(action === "connectDashboard"
          ? "Contul Stripe s-a deschis într-o filă nouă."
          : "Finalizează pașii în fila Stripe, apoi revino aici și apasă Actualizează.");
      } else {
        if (tab) tab.close();
        throw new Error("Linkul Stripe nu este disponibil.");
      }
    } catch (cause) {
      if (tab) tab.close();
      setError(cause.message);
    } finally {
      setBusy("");
    }
  }

  async function requestPayout() {
    if (figures.available <= 0 || !await confirmAction({
      title: "Soliciți transferul?",
      description: `${formatRon(figures.available)} vor fi transferați către contul tău Stripe.`,
      confirmLabel: "Solicită transferul",
    })) return;
    setError("");
    setNotice("");
    setBusy("payout");
    const tab = window.open("about:blank", "_blank");
    if (tab) tab.opener = null;
    try {
      const result = await accountRequest("payout", { method: "POST", body: JSON.stringify({ businessType }) });
      if (result.status === "requires_onboarding" && validStripeUrl(result.url)) {
        if (tab) tab.location.replace(result.url);
        else window.location.assign(result.url);
        setNotice("Configurează încasările în fila Stripe, apoi revino aici.", "info");
      } else if (result.status === "paid_out") {
        if (tab) tab.close();
        setNotice(`${formatRon(result.amount)} au fost trimiși către contul Stripe.`);
        await refresh();
      } else {
        if (tab) tab.close();
        throw new Error("Răspuns neașteptat de la Stripe.");
      }
    } catch (cause) {
      if (tab) tab.close();
      setError(cause.message);
    } finally {
      setBusy("");
    }
  }

  return (
    <>
      <Head><title>Contul meu | PINLEND</title><meta name="description" content="Gestionează contul, locația, identitatea și încasările PINLEND." /></Head>
      <AppHeader />

      <main className="mx-auto max-w-7xl px-5 pb-24 pt-12 md:px-8 md:pt-16">
        {loading ? <BrandLoader className="py-20" label="Se încarcă contul..." /> : sessionCheckError && !user ? (
          <div className="mx-auto max-w-[490px] rounded-[20px] bg-white p-8 text-center shadow-sm"><p className="text-[#434750]">{sessionCheckError}</p><button className="account-button mt-6" onClick={retrySession} type="button">Reîncearcă</button></div>
        ) : !user ? (
          <div className="flex min-h-[calc(100dvh-15rem)] items-center justify-center">
            <form autoComplete="off" className="w-full max-w-[490px] rounded-[20px] bg-white p-6 shadow-sm md:p-9" onSubmit={submitAuth}>
              <div className="flex gap-2 rounded-full bg-[#F3F3F3] p-1"><button className={`flex-1 rounded-full px-4 py-3 text-sm font-bold ${authMode === "login" ? "bg-[#30578F] text-white" : "text-[#434750]"}`} onClick={() => { setAuthMode("login"); setForm({ fullName: "", email: "", phone: "", password: "" }); setCredentialsEditable(false); setError(""); }} type="button">Autentificare</button><button className={`flex-1 rounded-full px-4 py-3 text-sm font-bold ${authMode === "register" ? "bg-[#30578F] text-white" : "text-[#434750]"}`} onClick={() => { setAuthMode("register"); setForm({ fullName: "", email: "", phone: "", password: "" }); setCredentialsEditable(false); setError(""); }} type="button">Cont nou</button></div>
              <h2 className="mt-7 text-2xl font-extrabold">{authMode === "login" ? "Bine ai revenit" : "Creează cont"}</h2>
              {authMode === "register" && <><label className="mt-5 block text-sm font-bold" htmlFor="full-name">Nume complet</label><Input className="account-input" id="full-name" onChange={(event) => setForm({ ...form, fullName: event.target.value })} required value={form.fullName} /><label className="mt-5 block text-sm font-bold" htmlFor="phone">Telefon</label><Input className="account-input" id="phone" onChange={(event) => setForm({ ...form, phone: event.target.value })} placeholder="+407..." required type="tel" value={form.phone} /></>}
              <label className="mt-5 block text-sm font-bold" htmlFor="account-email-entry">Email</label><Input autoComplete="off" className="account-input" data-1p-ignore data-lpignore="true" id="account-email-entry" onChange={(event) => setForm({ ...form, email: event.target.value })} onFocus={() => setCredentialsEditable(true)} readOnly={!credentialsEditable} required type="email" value={form.email} />
              <label className="mt-5 block text-sm font-bold" htmlFor="account-password-entry">Parolă</label><Input autoComplete="new-password" className="account-input" data-1p-ignore data-lpignore="true" id="account-password-entry" minLength={8} onChange={(event) => setForm({ ...form, password: event.target.value })} onFocus={() => setCredentialsEditable(true)} readOnly={!credentialsEditable} required type="password" value={form.password} />
              
              <button className="mt-7 w-full rounded-full bg-[#30578F] px-6 py-4 font-bold text-white disabled:opacity-50" disabled={busy === "auth"} type="submit">{busy === "auth" ? "Se procesează..." : authMode === "login" ? "Intră în cont" : "Creează contul"}</button>
            </form>
          </div>
        ) : (
          <>
            <div className="flex flex-col justify-between gap-5 md:flex-row md:items-end"><div className="flex flex-col items-start gap-4 sm:flex-row sm:items-center sm:gap-5"><UserAvatar className="size-16 ring-4 ring-white shadow-md md:size-20" fallbackClassName="text-xl md:text-2xl" user={user} /><div><p className="font-mono text-xs uppercase tracking-[0.25em] text-[#30578F]">Contul meu</p><h1 className="mt-3 font-display text-4xl font-extrabold md:text-6xl">Salut, {user.fullName?.split(" ")[0] || "bine ai venit"}.</h1><p className="mt-3 text-[#434750]">{user.email}</p></div></div><div className="flex gap-3"><button className="rounded-full border border-black/15 px-5 py-2.5 text-sm font-bold hover:border-[#30578F]" onClick={() => refresh().catch((cause) => setError(cause.message))} type="button">Actualizează</button><button className="rounded-full border border-red-400 px-5 py-2.5 text-sm font-bold transition-colors hover:border-red-600 hover:bg-red-50" disabled={busy === "logout"} onClick={logout} type="button">Ieși din cont</button></div></div>
            
            
            

            <nav aria-label="Navigare cont" className="mt-9 flex gap-2 overflow-x-auto rounded-[20px] bg-white p-2 shadow-sm">
              {accountSections.map((section) => <button
                aria-current={activeSection === section.id ? "page" : undefined}
                className={`flex shrink-0 items-center gap-2 rounded-[14px] px-4 py-3 text-sm font-bold transition-[background-color,color] duration-[220ms] ${activeSection === section.id ? "bg-[#30578F] text-white" : "text-[#434750] hover:bg-[#E7F0FD]"}`}
                key={section.id}
                onClick={() => setActiveSection(section.id)}
                type="button"
              ><span aria-hidden="true" className="material-symbols-outlined text-[20px]">{section.icon}</span>{section.label}</button>)}
            </nav>

            {(activeSection === "overview" || activeSection === "earnings") && <section className="mt-8 grid gap-4 md:grid-cols-3"><Metric label="Câștiguri din închirieri" value={formatRon(figures.earned)} note="Închirieri finalizate și plătite" /><Metric label="Disponibili pentru transfer" value={formatRon(figures.available)} note="După perioada de așteptare" /><Metric label="Trimiși către Stripe" value={formatRon(figures.paid)} note="Transferuri inițiate" /></section>}

            {activeSection === "listings" && <section className="account-card mt-8">
              <CardHeading icon="inventory_2" title="Anunțurile mele" />
              <p className="mt-2 text-sm text-[#626977]">Anunțurile publicate din contul tău.</p><Link className="account-button mt-4 inline-block" href="/anunturile-mele">Adaugă sau editează anunțuri</Link>
              {listings.length === 0 ? <p className="mt-6 text-[#434750]">Nu ai încă anunțuri. <Link className="font-bold text-[#30578F] underline" href="/">Vezi anunțurile</Link></p> : <div className="mt-6 grid gap-3 md:grid-cols-2">{listings.map((item) => <Link aria-label={`Editează anunțul ${item.title}`} className="flex items-center gap-4 rounded-2xl border border-black/10 p-3 transition-colors hover:border-[#30578F]" href={`/anunturile-mele?id=${encodeURIComponent(item._id || item.id)}`} key={item._id || item.id}>
                <ListingThumbnail item={item} />
                <span className="min-w-0 flex-1"><span className="block truncate font-bold">{item.title}</span><span className="mt-1 block text-sm text-[#626977]">{formatRon(item.pricePerDay)} / zi · {item.city}</span><span className="mt-1 block text-xs font-bold text-[#30578F]">{item.isClosedByAdmin ? "Închis de administrator" : item.isAvailable ? "Disponibil" : "Indisponibil"}</span></span><span aria-hidden="true" className="material-symbols-outlined text-[#30578F]">arrow_forward</span>
              </Link>)}</div>}
            </section>}

            {activeSection === "rentals" && <section className="account-card mt-8">
              <CardHeading icon="handshake" title="Închirierile mele" />
              {visibleRentals.some((order) => ["confirmed", "active"].includes(order.status)) && <div className="mt-5 flex items-start gap-3 rounded-2xl bg-[#E7F0FD] p-4 text-sm text-[#30578F]">
                <span aria-hidden="true" className="material-symbols-outlined">phone_iphone</span>
                <p><strong>Returul cu QR se face din aplicația PINLEND.</strong> Chiriașul arată codul pe telefon, iar proprietarul îl scanează și confirmă primirea. <Link className="font-bold underline" href="/retur">Vezi cum descarci aplicația</Link>.</p>
              </div>}
              <div className="mt-6 flex flex-wrap gap-2" aria-label="Rol în închiriere">{[["renting", "Închiriez"], ["lending", "De la mine"]].map(([value, label]) => <button aria-pressed={rentalPerspective === value} className={`rounded-full px-5 py-2.5 text-sm font-bold transition-[background-color,color,box-shadow] duration-[220ms] ${rentalPerspective === value ? "bg-[#30578F] text-white shadow-[0_2px_6px_#00000014]" : "bg-[#E7F0FD] text-[#30578F]"}`} key={value} onClick={() => setRentalPerspective(value)} type="button">{label}</button>)}</div>
              <div className="mt-5 flex gap-5 border-b border-black/10" aria-label="Starea închirierilor">{[[false, "Active"], [true, "Istoric"]].map(([value, label]) => <button aria-pressed={rentalHistory === value} className={`border-b-2 pb-3 text-sm font-bold transition-[border-color,color] duration-[180ms] ${rentalHistory === value ? "border-[#30578F] text-[#30578F]" : "border-transparent text-[#626977]"}`} key={label} onClick={() => setRentalHistory(value)} type="button">{label}</button>)}</div>
              <div className="account-rentals-switch" key={`${rentalPerspective}-${rentalHistory}`}>
                {visibleRentals.length === 0 ? <p className="py-10 text-center text-[#626977]">Nu există închirieri în această secțiune.</p> : <div className="divide-y divide-black/10">{visibleRentals.map((order) => <RentalRow busy={busy === `rental-${order._id || order.id}`} key={order._id || order.id} onDecision={decideRental} order={order} lending={rentalPerspective === "lending"} />)}</div>}
              </div>
            </section>}

            {activeSection === "profile" && <div className="mt-8 grid gap-6 lg:grid-cols-2">
              <section className="account-card lg:col-span-2"><CardHeading icon="account_circle" title="Fotografia de profil" /><div className="mt-5 flex flex-wrap items-center gap-5"><UserAvatar className="size-24 ring-4 ring-[#E7F0FD]" fallbackClassName="text-3xl" user={user} /><div><p className="text-sm text-[#626977]">Fotografia ta apare în cont și lângă anunțurile tale.</p><label className="account-button mt-4 inline-flex cursor-pointer items-center rounded-full" htmlFor="account-avatar-input">{busy === "avatar" ? "Se încarcă..." : user.avatarUrl ? "Schimbă fotografia" : "Adaugă fotografie"}</label><input accept="image/jpeg,image/png,image/webp" className="sr-only" disabled={busy === "avatar"} id="account-avatar-input" onChange={uploadAvatar} type="file" /><p className="mt-2 text-xs text-[#626977]">JPG, PNG sau WebP, maximum 10 MB.</p></div></div></section>
              <section className="account-card"><CardHeading icon="verified_user" title="Verificarea identității" /><p className="mt-3 text-[#434750]">Confirmă identitatea cu documentul tău prin Stripe Identity.</p><StatusPill good={identity?.identityVerified} text={identity?.identityVerified ? "Identitate verificată" : identity?.processing ? "În curs de verificare" : "Verificare necesară"} /><div className="mt-6 flex flex-wrap gap-3">{!identity?.identityVerified && <button className="account-button" disabled={Boolean(busy)} onClick={() => openStripe("identityStart")} type="button">{busy === "identityStart" ? "Se deschide..." : "Verifică buletinul"}</button>}<button className="account-button-light" onClick={() => refresh().catch((cause) => setError(cause.message))} type="button">Verifică starea</button></div></section>
              <section className="account-card"><CardHeading icon="location_on" title="Locația mea" /><p className="mt-3 text-[#434750]">Orașul și coordonatele sunt sincronizate cu aplicația mobilă.</p><form className="mt-5" onSubmit={saveLocation}><label className="text-sm font-bold" htmlFor="city">Oraș</label><Input className="account-input" id="city" onChange={(event) => { setCity(event.target.value); setCoordinates(null); }} placeholder="Ex. București" required value={city} /><p className="mt-3 text-xs text-[#626977]">{coordinates ? `Coordonate: ${coordinates.latitude.toFixed(4)}, ${coordinates.longitude.toFixed(4)}` : "Coordonatele sunt opționale."}</p><div className="mt-5 flex flex-wrap gap-3"><button className="account-button-light" disabled={busy === "geo"} onClick={useMyLocation} type="button">{busy === "geo" ? "Se caută..." : "Folosește locația actuală"}</button><button className="account-button" disabled={busy === "location"} type="submit">{busy === "location" ? "Se salvează..." : "Salvează locația"}</button></div></form></section>
              <section className="account-card lg:col-span-2"><CardHeading icon="help" title="Ajutor și cont" /><div className="mt-5 flex flex-wrap gap-3"><Link className="account-button-light" href="/support">Suport</Link><Link className="account-button-light" href="/privacy-policy">Confidențialitate</Link><Link className="account-button-light" href="/account-deletion">Ștergerea contului</Link></div></section>
            </div>}

            {activeSection === "earnings" && <div className="mt-8 grid gap-6 lg:grid-cols-2">
              <section className="account-card">
                <div className="flex items-start justify-between gap-4">
                  <CardHeading icon="account_balance" title="Contul de încasări" />
                  {connectReady && <span aria-label="Cont de încasări activ" className="flex size-9 shrink-0 items-center justify-center rounded-full bg-emerald-50 text-emerald-600" role="img"><CircleCheck aria-hidden="true" className="size-5" /></span>}
                </div>
                <p className="mt-3 text-[#434750]">{connectReady ? "Contul Stripe Connect este activ și pregătit pentru încasări." : "Configurează contul Stripe pentru a primi banii din închirieri."}</p>
                {connectReady ? <button className="account-button mt-6" disabled={Boolean(busy)} onClick={() => openStripe("connectDashboard")} type="button">Deschide Stripe Connect ↗</button> : <>
                  <div className="mt-5 flex flex-wrap items-center gap-3"><FormSelect aria-label="Tip de cont" className="account-input mt-0 w-auto" onChange={(event) => setBusinessType(event.target.value)} value={businessType}><option value="individual">Persoană fizică</option><option value="company">Firmă</option></FormSelect><button className="account-button" disabled={Boolean(busy)} onClick={() => openStripe("connectStart", { businessType })} type="button">{connect?.connected ? "Continuă configurarea" : "Configurează încasările"}</button></div>
                  {connect?.connected && <button className="mt-4 text-sm font-bold text-[#30578F]" disabled={Boolean(busy)} onClick={() => openStripe("connectDashboard")} type="button">Deschide contul Stripe ↗</button>}
                </>}
              </section>
              <section className="account-card"><CardHeading icon="payments" title="Retrage banii" /><p className="mt-3 text-[#434750]">Poți cere transferul sumelor eligibile în contul Stripe. Nu sunt incluse închirierile aflate încă în desfășurare.</p><p className="mt-5 text-3xl font-extrabold">{formatRon(figures.available)}</p><button className="account-button mt-5" disabled={Boolean(busy) || figures.available <= 0} onClick={requestPayout} type="button">{busy === "payout" ? "Se procesează..." : "Cere transferul"}</button></section>
            </div>}

            {activeSection === "earnings" && <section className="account-card mt-8"><CardHeading icon="receipt_long" title="Istoricul încasărilor" /><p className="mt-2 text-sm text-[#434750]">{eligibleOrders.length} închirieri finalizate și plătite</p>{orders.length === 0 ? <p className="mt-6 text-[#434750]">Nu există încă închirieri pentru anunțurile tale.</p> : <div className="mt-6 overflow-x-auto"><table className="w-full min-w-[660px] text-left text-sm"><thead className="border-b border-black/10 text-xs uppercase tracking-widest text-[#626977]"><tr><th className="pb-3">Anunț</th><th className="pb-3">Închiriere</th><th className="pb-3">Câștig</th><th className="pb-3">Transfer</th></tr></thead><tbody>{orders.map((order) => <tr className="border-b border-black/5" key={order._id || order.id}><td className="py-4 font-bold">{order.productSnapshot?.title || "Anunț"}</td><td className="py-4 text-[#434750]">{rentalStatus(order.status)}</td><td className="py-4">{formatRon(order.ownerEarnings)}</td><td className="py-4 text-[#434750]">{payoutStatus(order.payoutStatus)}</td></tr>)}</tbody></table></div>}</section>}
          </>
        )}
      </main>
    </>
  );
}

function CardHeading({ icon, title }) { return <h2 className="flex items-center gap-3 text-xl font-extrabold"><span className="material-symbols-outlined text-[#30578F]">{icon}</span>{title}</h2>; }
function ListingThumbnail({ item }) {
  const src = item.images?.find((image) => image.url && image.type !== "video" && !image.contentType?.startsWith("video/"))?.url;
  const [failedSrc, setFailedSrc] = useState("");
  return src && failedSrc !== src
    ? <img alt="" className="h-20 w-20 shrink-0 rounded-xl object-cover" onError={() => setFailedSrc(src)} src={src} />
    : <span aria-hidden="true" className="material-symbols-outlined flex h-20 w-20 shrink-0 items-center justify-center rounded-xl bg-[#E7F0FD] text-[#30578F]">image</span>;
}
function RentalRow({ order, lending, onDecision, busy }) {
  const title = order.productSnapshot?.title || "Anunț";
  const slug = order.productSnapshot?.slug;
  const readyForOwner = order.status === "pending" && (order.paymentStatus === "captured" || (order.paymentStatus === "authorized" && order.renterVerifiedAt));
  return <div className="flex flex-col gap-4 py-5 sm:flex-row sm:items-center sm:justify-between">
    <div className="min-w-0"><p className="font-extrabold">{title}</p><p className="mt-1 text-sm text-[#626977]">{formatDate(order.startDate)} – {formatDate(order.endDate)}</p><p className="mt-2 text-sm font-bold text-[#30578F]">{rentalStatus(order.status)}</p>{!lending && order.status === "pending" && slug && !order.renterVerifiedAt && <Link className="mt-2 inline-block text-sm font-bold text-[#30578F] underline" href={`/inchiriaza/${encodeURIComponent(slug)}?orderId=${encodeURIComponent(order._id || order.id)}`}>Continuă închirierea</Link>}{order.contractPdfUrl && <a className="mt-2 block text-xs font-bold text-[#30578F] underline" href={order.contractPdfUrl} rel="noopener noreferrer" target="_blank">Vezi contractul semnat</a>}{lending && order.status === "pending" && !readyForOwner && <p className="mt-1 text-xs text-[#626977]">Se așteaptă plata și verificarea locatarului.</p>}{lending && readyForOwner && <div className="mt-3 flex gap-2"><button className="rounded-full bg-[#30578F] px-4 py-2 text-xs font-bold text-white disabled:opacity-50" disabled={busy} onClick={() => onDecision(order._id || order.id, "rentalAccept")} type="button">Acceptă</button><button className="rounded-full border border-red-300 px-4 py-2 text-xs font-bold text-red-700 disabled:opacity-50" disabled={busy} onClick={() => onDecision(order._id || order.id, "rentalReject")} type="button">Refuză</button></div>}</div>
    <div className="flex shrink-0 items-center gap-5"><p className="font-bold">{formatRon(lending ? order.ownerEarnings : order.total)}</p>{["confirmed", "active"].includes(order.status) && <Link className="text-sm font-bold text-[#30578F]" href="/retur">Retur în aplicație</Link>}{slug && <Link aria-label={`Vezi ${title}`} className="flex h-10 w-10 items-center justify-center rounded-full bg-[#E7F0FD] text-[#30578F]" href={`/anunt/${encodeURIComponent(slug)}`}><span aria-hidden="true" className="material-symbols-outlined">arrow_forward</span></Link>}</div>
  </div>;
}
function Metric({ label, value, note }) { return <div className="rounded-[18px] bg-white p-6 shadow-sm"><p className="text-sm font-bold text-[#434750]">{label}</p><p className="mt-4 text-3xl font-extrabold">{value}</p><p className="mt-2 text-xs text-[#626977]">{note}</p></div>; }
function StatusPill({ good, text }) { return <span className={`mt-5 inline-flex rounded-full px-4 py-2 text-xs font-bold ${good ? "bg-green-100 text-green-800" : "bg-[#E7F0FD] text-[#30578F]"}`}>{text}</span>; }
function rentalStatus(value) { return ({ pending: "În așteptare", confirmed: "Confirmată", active: "În desfășurare", completed: "Finalizată", cancelled: "Anulată", rejected: "Respinsă" })[value] || value || "—"; }
function payoutStatus(value) { return ({ not_ready: "Indisponibil", pending_onboarding: "Configurare Stripe", ready: "Pregătit", held_until_return: "În așteptare", eligible: "Disponibil", processing: "În procesare", paid_out: "Trimis către Stripe", failed: "Eșuat" })[value] || value || "—"; }
