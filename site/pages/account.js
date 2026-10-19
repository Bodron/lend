import Head from "next/head";
import Link from "next/link";
import { useCallback, useEffect, useMemo, useState } from "react";
import BrandLogo from "../components/BrandLogo";

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
  const response = await fetch(`/api/account/${action}`, {
    credentials: "same-origin",
    cache: "no-store",
    ...options,
    headers: { "Content-Type": "application/json", ...options.headers },
  });
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
  const [sectionError, setSectionError] = useState("");
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [busy, setBusy] = useState("");
  const [authMode, setAuthMode] = useState("login");
  const [form, setForm] = useState({ fullName: "", email: "", phone: "", password: "" });
  const [city, setCity] = useState("");
  const [coordinates, setCoordinates] = useState(null);
  const [businessType, setBusinessType] = useState("individual");

  const refresh = useCallback(async () => {
    setSectionError("");
    let profile;
    try {
      profile = await accountRequest("me");
    } catch (cause) {
      if (cause.status === 401) setUser(null);
      throw cause;
    }
    setUser(profile);
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
    if (results[4].status === "fulfilled") setConnect(results[4].value);
    if (results.some((result) => result.status === "rejected")) {
      setSectionError("Unele date nu au putut fi încărcate. Apasă Actualizează pentru a încerca din nou.");
    }
  }, []);

  useEffect(() => {
    const stripeResult = new URLSearchParams(window.location.search).get("stripe");
    if (stripeResult === "return") Promise.resolve().then(() => setNotice("Ai revenit de la Stripe. Starea contului se actualizează."));
    if (stripeResult === "refresh") Promise.resolve().then(() => setNotice("Linkul Stripe a expirat. Poți relua configurarea de aici."));
    Promise.resolve().then(refresh).catch((cause) => {
      if (cause.status !== 401) setError(cause.message);
    }).finally(() => setLoading(false));
    const onFocus = () => {
      if (document.visibilityState === "visible") {
        refresh().catch(() => {});
      }
    };
    document.addEventListener("visibilitychange", onFocus);
    return () => document.removeEventListener("visibilitychange", onFocus);
  }, [refresh]);

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
    } catch (cause) {
      setError(cause.message);
    } finally {
      setBusy("");
    }
  }

  async function logout() {
    setBusy("logout");
    try {
      await accountRequest("logout", { method: "POST" });
      setUser(null);
      setOrders([]);
      setRenterOrders([]);
      setListings([]);
      setIdentity(null);
      setConnect(null);
      setError("");
      setNotice("");
    } catch (cause) {
      setError(cause.message);
    } finally {
      setBusy("");
    }
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
      setNotice("Locația a fost salvată.");
    } catch (cause) {
      setError(cause.message);
    } finally {
      setBusy("");
    }
  }

  function useMyLocation() {
    setError("");
    if (!navigator.geolocation) return setError("Browserul nu oferă acces la locație.");
    setBusy("geo");
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        setCoordinates({ latitude: coords.latitude, longitude: coords.longitude });
        setNotice("Coordonatele au fost preluate. Introdu orașul și salvează locația.");
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
        setNotice("Stripe verifică documentul. Actualizează starea peste câteva momente.");
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
    if (figures.available <= 0 || !window.confirm(`Ceri transferul a ${formatRon(figures.available)} către contul tău Stripe?`)) return;
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
        setNotice("Configurează încasările în fila Stripe, apoi revino aici.");
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
      <header className="border-b border-black/10 bg-white">
        <div className="mx-auto flex h-20 max-w-7xl items-center justify-between px-5 md:px-8"><BrandLogo /><nav className="flex items-center gap-5 text-sm font-bold"><Link className="hover:text-[#30578F]" href="/archive">Anunțuri</Link><Link className="hidden hover:text-[#30578F] sm:inline" href="/">Acasă</Link></nav></div>
      </header>

      <main className="mx-auto max-w-7xl px-5 pb-24 pt-12 md:px-8 md:pt-16">
        {loading ? <p className="py-20 text-center text-[#434750]">Se încarcă contul...</p> : !user ? (
          <div className="flex min-h-[calc(100dvh-15rem)] items-center justify-center">
            <form className="w-full max-w-[490px] rounded-[20px] bg-white p-6 shadow-sm md:p-9" onSubmit={submitAuth}>
              <div className="flex gap-2 rounded-full bg-[#F3F3F3] p-1"><button className={`flex-1 rounded-full px-4 py-3 text-sm font-bold ${authMode === "login" ? "bg-[#30578F] text-white" : "text-[#434750]"}`} onClick={() => { setAuthMode("login"); setError(""); }} type="button">Autentificare</button><button className={`flex-1 rounded-full px-4 py-3 text-sm font-bold ${authMode === "register" ? "bg-[#30578F] text-white" : "text-[#434750]"}`} onClick={() => { setAuthMode("register"); setError(""); }} type="button">Cont nou</button></div>
              <h2 className="mt-7 text-2xl font-extrabold">{authMode === "login" ? "Bine ai revenit" : "Creează cont"}</h2>
              {authMode === "register" && <><label className="mt-5 block text-sm font-bold" htmlFor="full-name">Nume complet</label><input className="account-input" id="full-name" onChange={(event) => setForm({ ...form, fullName: event.target.value })} required value={form.fullName} /><label className="mt-5 block text-sm font-bold" htmlFor="phone">Telefon</label><input className="account-input" id="phone" onChange={(event) => setForm({ ...form, phone: event.target.value })} placeholder="+407..." required type="tel" value={form.phone} /></>}
              <label className="mt-5 block text-sm font-bold" htmlFor="email">Email</label><input autoComplete="email" className="account-input" id="email" onChange={(event) => setForm({ ...form, email: event.target.value })} required type="email" value={form.email} />
              <label className="mt-5 block text-sm font-bold" htmlFor="password">Parolă</label><input autoComplete={authMode === "login" ? "current-password" : "new-password"} className="account-input" id="password" minLength={8} onChange={(event) => setForm({ ...form, password: event.target.value })} required type="password" value={form.password} />
              {error && <p className="mt-5 rounded-xl bg-red-50 p-3 text-sm text-red-700" role="alert">{error}</p>}
              <button className="mt-7 w-full rounded-full bg-[#30578F] px-6 py-4 font-bold text-white disabled:opacity-50" disabled={busy === "auth"} type="submit">{busy === "auth" ? "Se procesează..." : authMode === "login" ? "Intră în cont" : "Creează contul"}</button>
            </form>
          </div>
        ) : (
          <>
            <div className="flex flex-col justify-between gap-5 md:flex-row md:items-end"><div><p className="font-mono text-xs uppercase tracking-[0.25em] text-[#30578F]">Contul meu</p><h1 className="mt-3 font-display text-4xl font-extrabold md:text-6xl">Salut, {user.fullName?.split(" ")[0] || "bine ai venit"}.</h1><p className="mt-3 text-[#434750]">{user.email}</p></div><div className="flex gap-3"><button className="rounded-full border border-black/15 px-5 py-2.5 text-sm font-bold hover:border-[#30578F]" onClick={() => refresh().catch((cause) => setError(cause.message))} type="button">Actualizează</button><button className="rounded-full border border-black/15 px-5 py-2.5 text-sm font-bold hover:border-red-400" disabled={busy === "logout"} onClick={logout} type="button">Ieși din cont</button></div></div>
            {error && <p className="mt-7 rounded-xl bg-red-50 p-4 text-red-700" role="alert">{error}</p>}
            {notice && <p className="mt-7 rounded-xl bg-[#E7F0FD] p-4 text-[#30578F]" role="status">{notice}</p>}
            {sectionError && <p className="mt-7 rounded-xl bg-amber-50 p-4 text-amber-800">{sectionError}</p>}

            <nav aria-label="Navigare cont" className="mt-9 flex gap-2 overflow-x-auto rounded-[20px] bg-white p-2 shadow-sm">
              {accountSections.map((section) => <button
                aria-current={activeSection === section.id ? "page" : undefined}
                className={`flex shrink-0 items-center gap-2 rounded-[14px] px-4 py-3 text-sm font-bold transition-colors ${activeSection === section.id ? "bg-[#30578F] text-white" : "text-[#434750] hover:bg-[#E7F0FD]"}`}
                key={section.id}
                onClick={() => setActiveSection(section.id)}
                type="button"
              ><span aria-hidden="true" className="material-symbols-outlined text-[20px]">{section.icon}</span>{section.label}</button>)}
            </nav>

            {(activeSection === "overview" || activeSection === "earnings") && <section className="mt-8 grid gap-4 md:grid-cols-3"><Metric label="Câștiguri din închirieri" value={formatRon(figures.earned)} note="Închirieri finalizate și plătite" /><Metric label="Disponibili pentru transfer" value={formatRon(figures.available)} note="După perioada de așteptare" /><Metric label="Trimiși către Stripe" value={formatRon(figures.paid)} note="Transferuri inițiate" /></section>}

            {activeSection === "overview" && <section className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              <AccountShortcut icon="inventory_2" label="Anunțurile mele" note={`${listings.length} anunțuri`} onClick={() => setActiveSection("listings")} />
              <AccountShortcut icon="shopping_bag" label="Închiriez" note={`${renterOrders.length} închirieri`} onClick={() => { setRentalPerspective("renting"); setRentalHistory(false); setActiveSection("rentals"); }} />
              <AccountShortcut icon="storefront" label="De la mine" note={`${orders.length} închirieri`} onClick={() => { setRentalPerspective("lending"); setRentalHistory(false); setActiveSection("rentals"); }} />
              <AccountShortcut icon="verified_user" label="Contul meu" note={identity?.identityVerified ? "Identitate verificată" : "Verifică identitatea"} onClick={() => setActiveSection("profile")} />
            </section>}

            {activeSection === "listings" && <section className="account-card mt-8">
              <CardHeading icon="inventory_2" title="Anunțurile mele" />
              <p className="mt-2 text-sm text-[#626977]">Anunțurile publicate din contul tău.</p>
              {listings.length === 0 ? <p className="mt-6 text-[#434750]">Nu ai încă anunțuri. <Link className="font-bold text-[#30578F] underline" href="/archive">Vezi anunțurile</Link></p> : <div className="mt-6 grid gap-3 md:grid-cols-2">{listings.map((item) => <Link className="flex items-center gap-4 rounded-2xl border border-black/10 p-3 transition-colors hover:border-[#30578F]" href={item.slug ? `/anunt/${encodeURIComponent(item.slug)}` : "/archive"} key={item._id || item.id}>
                {item.images?.[0]?.url ? <img alt="" className="h-20 w-20 rounded-xl object-cover" src={item.images[0].url} /> : <span aria-hidden="true" className="material-symbols-outlined flex h-20 w-20 items-center justify-center rounded-xl bg-[#E7F0FD] text-[#30578F]">image</span>}
                <span className="min-w-0 flex-1"><span className="block truncate font-bold">{item.title}</span><span className="mt-1 block text-sm text-[#626977]">{formatRon(item.pricePerDay)} / zi · {item.city}</span><span className="mt-1 block text-xs font-bold text-[#30578F]">{item.isClosedByAdmin ? "Închis de administrator" : item.isAvailable ? "Disponibil" : "Indisponibil"}</span></span><span aria-hidden="true" className="material-symbols-outlined text-[#30578F]">arrow_forward</span>
              </Link>)}</div>}
            </section>}

            {activeSection === "rentals" && <section className="account-card mt-8">
              <CardHeading icon="handshake" title="Închirierile mele" />
              <div className="mt-6 flex flex-wrap gap-2" aria-label="Rol în închiriere">{[["renting", "Închiriez"], ["lending", "De la mine"]].map(([value, label]) => <button className={`rounded-full px-5 py-2.5 text-sm font-bold ${rentalPerspective === value ? "bg-[#30578F] text-white" : "bg-[#E7F0FD] text-[#30578F]"}`} key={value} onClick={() => setRentalPerspective(value)} type="button">{label}</button>)}</div>
              <div className="mt-5 flex gap-5 border-b border-black/10" aria-label="Starea închirierilor">{[[false, "Active"], [true, "Istoric"]].map(([value, label]) => <button className={`border-b-2 pb-3 text-sm font-bold ${rentalHistory === value ? "border-[#30578F] text-[#30578F]" : "border-transparent text-[#626977]"}`} key={label} onClick={() => setRentalHistory(value)} type="button">{label}</button>)}</div>
              {visibleRentals.length === 0 ? <p className="py-10 text-center text-[#626977]">Nu există închirieri în această secțiune.</p> : <div className="divide-y divide-black/10">{visibleRentals.map((order) => <RentalRow key={order._id || order.id} order={order} lending={rentalPerspective === "lending"} />)}</div>}
            </section>}

            {activeSection === "profile" && <div className="mt-8 grid gap-6 lg:grid-cols-2">
              <section className="account-card"><CardHeading icon="verified_user" title="Verificarea identității" /><p className="mt-3 text-[#434750]">Confirmă identitatea cu documentul tău prin Stripe Identity.</p><StatusPill good={identity?.identityVerified} text={identity?.identityVerified ? "Identitate verificată" : identity?.processing ? "În curs de verificare" : "Verificare necesară"} /><div className="mt-6 flex flex-wrap gap-3">{!identity?.identityVerified && <button className="account-button" disabled={Boolean(busy)} onClick={() => openStripe("identityStart")} type="button">{busy === "identityStart" ? "Se deschide..." : "Verifică buletinul"}</button>}<button className="account-button-light" onClick={() => refresh().catch((cause) => setError(cause.message))} type="button">Verifică starea</button></div></section>
              <section className="account-card"><CardHeading icon="location_on" title="Locația mea" /><p className="mt-3 text-[#434750]">Orașul și coordonatele sunt sincronizate cu aplicația mobilă.</p><form className="mt-5" onSubmit={saveLocation}><label className="text-sm font-bold" htmlFor="city">Oraș</label><input className="account-input" id="city" onChange={(event) => { setCity(event.target.value); setCoordinates(null); }} placeholder="Ex. București" required value={city} /><p className="mt-3 text-xs text-[#626977]">{coordinates ? `Coordonate: ${coordinates.latitude.toFixed(4)}, ${coordinates.longitude.toFixed(4)}` : "Coordonatele sunt opționale."}</p><div className="mt-5 flex flex-wrap gap-3"><button className="account-button-light" disabled={busy === "geo"} onClick={useMyLocation} type="button">{busy === "geo" ? "Se caută..." : "Folosește locația actuală"}</button><button className="account-button" disabled={busy === "location"} type="submit">{busy === "location" ? "Se salvează..." : "Salvează locația"}</button></div></form></section>
              <section className="account-card lg:col-span-2"><CardHeading icon="help" title="Ajutor și cont" /><div className="mt-5 flex flex-wrap gap-3"><Link className="account-button-light" href="/support">Suport</Link><Link className="account-button-light" href="/privacy-policy">Confidențialitate</Link><Link className="account-button-light" href="/account-deletion">Ștergerea contului</Link></div></section>
            </div>}

            {activeSection === "earnings" && <div className="mt-8 grid gap-6 lg:grid-cols-2">
              <section className="account-card">
                <CardHeading icon="account_balance" title="Contul de încasări" />
                <p className="mt-3 text-[#434750]">{connectReady ? "Contul Stripe Connect este activ și pregătit pentru încasări." : "Configurează contul Stripe pentru a primi banii din închirieri."}</p>
                <StatusPill good={connectReady} text={!connect?.connected ? "Neconfigurat" : connectReady ? "Pregătit pentru încasări" : "Configurare în curs"} />
                {connect?.errors?.length > 0 && <p className="mt-4 text-sm text-red-700">{connect.errors.join(" ")}</p>}
                {connectReady ? <button className="account-button mt-6" disabled={Boolean(busy)} onClick={() => openStripe("connectDashboard")} type="button">Deschide Stripe Connect ↗</button> : <>
                  <div className="mt-5 flex flex-wrap items-center gap-3"><select aria-label="Tip de cont" className="account-input mt-0 w-auto" onChange={(event) => setBusinessType(event.target.value)} value={businessType}><option value="individual">Persoană fizică</option><option value="company">Firmă</option></select><button className="account-button" disabled={Boolean(busy)} onClick={() => openStripe("connectStart", { businessType })} type="button">{connect?.connected ? "Continuă configurarea" : "Configurează încasările"}</button></div>
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
function AccountShortcut({ icon, label, note, onClick }) {
  return <button className="flex min-h-32 flex-col items-start rounded-[18px] bg-white p-5 text-left shadow-sm transition-colors hover:bg-[#E7F0FD]" onClick={onClick} type="button"><span aria-hidden="true" className="material-symbols-outlined text-3xl text-[#30578F]">{icon}</span><span className="mt-3 font-extrabold">{label}</span><span className="mt-1 text-sm text-[#626977]">{note}</span></button>;
}
function RentalRow({ order, lending }) {
  const title = order.productSnapshot?.title || "Anunț";
  const slug = order.productSnapshot?.slug;
  return <div className="flex flex-col gap-4 py-5 sm:flex-row sm:items-center sm:justify-between">
    <div className="min-w-0"><p className="font-extrabold">{title}</p><p className="mt-1 text-sm text-[#626977]">{formatDate(order.startDate)} – {formatDate(order.endDate)}</p><p className="mt-2 text-sm font-bold text-[#30578F]">{rentalStatus(order.status)}</p></div>
    <div className="flex shrink-0 items-center gap-5"><p className="font-bold">{formatRon(lending ? order.ownerEarnings : order.total)}</p>{slug && <Link aria-label={`Vezi ${title}`} className="flex h-10 w-10 items-center justify-center rounded-full bg-[#E7F0FD] text-[#30578F]" href={`/anunt/${encodeURIComponent(slug)}`}><span aria-hidden="true" className="material-symbols-outlined">arrow_forward</span></Link>}</div>
  </div>;
}
function Metric({ label, value, note }) { return <div className="rounded-[18px] bg-white p-6 shadow-sm"><p className="text-sm font-bold text-[#434750]">{label}</p><p className="mt-4 text-3xl font-extrabold">{value}</p><p className="mt-2 text-xs text-[#626977]">{note}</p></div>; }
function StatusPill({ good, text }) { return <span className={`mt-5 inline-flex rounded-full px-4 py-2 text-xs font-bold ${good ? "bg-green-100 text-green-800" : "bg-[#E7F0FD] text-[#30578F]"}`}>{text}</span>; }
function rentalStatus(value) { return ({ pending: "În așteptare", confirmed: "Confirmată", active: "În desfășurare", completed: "Finalizată", cancelled: "Anulată", rejected: "Respinsă" })[value] || value || "—"; }
function payoutStatus(value) { return ({ not_ready: "Indisponibil", pending_onboarding: "Configurare Stripe", ready: "Pregătit", held_until_return: "În așteptare", eligible: "Disponibil", processing: "În procesare", paid_out: "Trimis către Stripe", failed: "Eșuat" })[value] || value || "—"; }
