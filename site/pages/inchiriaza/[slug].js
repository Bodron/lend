/* eslint-disable @next/next/no-img-element */
import Head from "next/head";
import Link from "next/link";
import { useCallback, useEffect, useRef, useState } from "react";
import { loadStripe } from "@stripe/stripe-js";
import PublicHeader from "../../components/PublicHeader";
import BrandLoader from "../../components/BrandLoader";
import { RentalDateField, RentalTimeField } from "../../components/RentalPeriodFields";
import { Button } from "../../components/ui/button";
import { ToggleGroup, ToggleGroupItem } from "../../components/ui/toggle-group";
import { getBackendApiUrl } from "../../lib/backendApi";
import { buildRentalContractPdf } from "../../lib/rentalContract";
import { useToastError } from "../../lib/useToastError";

const money = new Intl.NumberFormat("ro-RO", { maximumFractionDigits: 2 });
const ron = (value) => `${money.format(Number(value) || 0)} RON`;
const idOf = (item) => String(item?._id || item?.id || "");
const localDate = (date) => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
const plusDays = (key, count) => {
  const date = new Date(`${key}T12:00:00Z`);
  date.setUTCDate(date.getUTCDate() + count);
  return date.toISOString().slice(0, 10);
};
const nextMonth = (key) => {
  const date = new Date(`${key}T12:00:00Z`);
  const day = date.getUTCDate();
  const first = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + 1, 1));
  const last = new Date(Date.UTC(first.getUTCFullYear(), first.getUTCMonth() + 1, 0)).getUTCDate();
  first.setUTCDate(Math.min(day, last));
  return first.toISOString().slice(0, 10);
};
const daysBetween = (start, end) => Math.max(1, Math.round((Date.parse(`${end}T00:00:00Z`) - Date.parse(`${start}T00:00:00Z`)) / 86400000));
const modeLabel = { hour: "Oră", day: "Zi", month: "Lună" };

function currentPosition() {
  if (!navigator.geolocation) return Promise.resolve(null);
  return new Promise((resolve) => navigator.geolocation.getCurrentPosition(
    ({ coords }) => resolve({ renterLatitude: coords.latitude, renterLongitude: coords.longitude }),
    () => resolve(null),
    { enableHighAccuracy: false, timeout: 6000, maximumAge: 300000 },
  ));
}

async function request(action, options = {}) {
  const response = await fetch(`/api/account/${action}`, {
    credentials: "same-origin",
    cache: "no-store",
    ...options,
    headers: { "Content-Type": "application/json", ...options.headers },
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message = Array.isArray(data.message) ? data.message.join(" ") : data.message;
    const error = new Error(message || "Operațiunea nu a reușit.");
    error.status = response.status;
    throw error;
  }
  return data;
}

export async function getServerSideProps({ params, query, res }) {
  try {
    const response = await fetch(`${getBackendApiUrl()}/products/${encodeURIComponent(params.slug)}`, {
      cache: "no-store",
      signal: AbortSignal.timeout(10000),
    });
    if (response.status === 404) return { notFound: true };
    if (!response.ok) throw new Error(`Products API returned ${response.status}`);
    const product = await response.json();
    if (!product || product.isClosedByAdmin) return { notFound: true };
    const modes = Array.isArray(product.rentalModes) && product.rentalModes.length ? product.rentalModes : ["day"];
    const initialMode = modes.includes(query.mode) ? query.mode : modes[0];
    return { props: { product, initialMode, offerId: typeof query.offerId === "string" ? query.offerId : "", loadError: false } };
  } catch (error) {
    console.error("Could not load rental checkout:", error);
    res.statusCode = 503;
    return { props: { product: null, initialMode: "day", offerId: "", loadError: true } };
  }
}

function SignaturePad({ onChange }) {
  const canvasRef = useRef(null);
  const drawing = useRef(false);

  function point(event) {
    const rect = canvasRef.current.getBoundingClientRect();
    return { x: (event.clientX - rect.left) * canvasRef.current.width / rect.width, y: (event.clientY - rect.top) * canvasRef.current.height / rect.height };
  }
  function start(event) {
    event.preventDefault();
    const canvas = canvasRef.current;
    canvas.setPointerCapture(event.pointerId);
    const ctx = canvas.getContext("2d");
    const p = point(event);
    ctx.beginPath();
    ctx.moveTo(p.x, p.y);
    ctx.lineTo(p.x + 0.1, p.y + 0.1);
    ctx.strokeStyle = "#1b1b1b";
    ctx.lineWidth = 2.5;
    ctx.lineCap = "round";
    ctx.stroke();
    drawing.current = true;
    onChange(canvas.toDataURL("image/png"));
  }
  function move(event) {
    if (!drawing.current) return;
    const p = point(event);
    const ctx = canvasRef.current.getContext("2d");
    ctx.lineTo(p.x, p.y);
    ctx.stroke();
  }
  function stop() {
    if (!drawing.current) return;
    drawing.current = false;
    onChange(canvasRef.current.toDataURL("image/png"));
  }
  return <div>
    <canvas aria-label="Semnătura locatarului" className="h-36 w-full touch-none rounded-xl border border-[#C3C6D1] bg-white" height="180" onPointerCancel={stop} onPointerDown={start} onPointerMove={move} onPointerUp={stop} ref={canvasRef} width="700" />
    <button className="mt-2 text-sm font-bold text-[#30578F]" onClick={() => { canvasRef.current.getContext("2d").clearRect(0, 0, 700, 180); onChange(""); }} type="button">Șterge semnătura</button>
  </div>;
}

function PaymentForm({ publishableKey, clientSecret, orderId, onAuthorized, onError }) {
  const mountRef = useRef(null);
  const [stripeState, setStripeState] = useState(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    let cancelled = false;
    let paymentElement;
    loadStripe(publishableKey).then((stripe) => {
      if (!stripe || cancelled) return;
      const elements = stripe.elements({ clientSecret });
      paymentElement = elements.create("payment", { layout: "tabs" });
      paymentElement.mount(mountRef.current);
      setStripeState({ stripe, elements });
    }).catch((error) => { if (!cancelled) onError(error.message); });
    return () => { cancelled = true; paymentElement?.destroy(); };
  }, [publishableKey, clientSecret, onError]);

  async function pay(event) {
    event.preventDefault();
    if (!stripeState || busy) return;
    setBusy(true);
    try {
      const result = await stripeState.stripe.confirmPayment({
        elements: stripeState.elements,
        confirmParams: { return_url: `${window.location.origin}${window.location.pathname}?orderId=${encodeURIComponent(orderId)}` },
        redirect: "if_required",
      });
      if (result.error) throw new Error(result.error.message);
      if (result.paymentIntent?.status !== "requires_capture" && result.paymentIntent?.status !== "succeeded") {
        throw new Error("Plata este încă în procesare. Verifică din nou în câteva momente.");
      }
      await onAuthorized();
    } catch (error) { onError(error.message); }
    finally { setBusy(false); }
  }
  return <form className="mt-6" onSubmit={pay}>
    <div ref={mountRef} />
    <button className="mt-6 w-full rounded-full bg-[#30578F] px-6 py-4 font-bold text-white disabled:opacity-50" disabled={!stripeState || busy} type="submit">{busy ? "Se autorizează..." : "Autorizează plata"}</button>
  </form>;
}

export default function RentalCheckout({ product, initialMode, offerId, loadError }) {
  const [user, setUser] = useState(null);
  const [authState, setAuthState] = useState("loading");
  const [mode, setMode] = useState(initialMode);
  const [offer, setOffer] = useState(null);
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [pickupTime, setPickupTime] = useState(product?.pickupTime || "10:00");
  const [returnTime, setReturnTime] = useState(product?.returnTime || "18:00");
  const [availability, setAvailability] = useState(null);
  const [step, setStep] = useState("period");
  const [signature, setSignature] = useState("");
  const [order, setOrder] = useState(null);
  const [publishableKey, setPublishableKey] = useState("");
  const [identity, setIdentity] = useState(null);
  const [identityUrl, setIdentityUrl] = useState("");
  const [busy, setBusy] = useState("");
  const [, setError] = useToastError();
  const setCheckoutError = useCallback((message) => setError(message), [setError]);
  const modes = Array.isArray(product?.rentalModes) && product.rentalModes.length ? product.rentalModes : ["day"];
  const today = localDate(new Date());
  const minimumDate = mode === "hour" ? today : plusDays(today, 1);
  const finalEnd = offer ? String(offer.endDate).slice(0, 10) : mode === "hour" ? startDate : mode === "month" && startDate ? nextMonth(startDate) : endDate;
  const days = startDate && finalEnd ? daysBetween(startDate, finalEnd) : 0;
  const selectedMinutes = startDate && mode === "hour" ? Number(returnTime.slice(0, 2)) * 60 + Number(returnTime.slice(3)) - Number(pickupTime.slice(0, 2)) * 60 - Number(pickupTime.slice(3)) : 0;
  const hours = selectedMinutes > 0 ? Math.ceil(selectedMinutes / 60) : 0;
  const hourlyPrice = Math.max(1, Math.round(Number(product?.pricePerDay || 0) / 8));
  const calculatedSubtotal = mode === "hour" ? hourlyPrice * hours : mode === "month" ? Number(product?.pricePerMonth || 0) : days * Number(product?.pricePerDay || 0);
  const subtotal = offer?.amount || calculatedSubtotal;
  const serviceFee = Math.round(subtotal * 0.05);
  const total = subtotal + serviceFee + Number(product?.deposit || 0);
  const productId = idOf(product);
  const orderId = idOf(order);

  useEffect(() => {
    if (loadError) return;
    let cancelled = false;
    async function initialize() {
      try {
        const profile = await request("me");
        if (cancelled) return;
        setUser(profile);
        setAuthState("signed-in");
        if (offerId && !new URLSearchParams(window.location.search).get("orderId")) {
          const thread = await request(`messageThread?productId=${productId}`);
          const selectedOffer = thread.offers?.find((item) => idOf(item) === offerId && item.senderId === (profile.id || profile._id));
          if (!selectedOffer || !["accepted", "checkout_started"].includes(selectedOffer.status)) throw new Error("Oferta nu mai este disponibilă.");
          if (cancelled) return;
          setOffer(selectedOffer);
          setMode(selectedOffer.rentalMode);
          setStartDate(String(selectedOffer.startDate).slice(0, 10));
          setEndDate(String(selectedOffer.endDate).slice(0, 10));
        }
        const resumeId = new URLSearchParams(window.location.search).get("orderId");
        if (resumeId) {
          const orders = await request("renterOrders");
          let existing = Array.isArray(orders) ? orders.find((item) => idOf(item) === resumeId && String(item.productId) === productId) : null;
          if (cancelled) return;
          if (!existing) throw new Error("Închirierea nu a fost găsită în contul tău.");
          if (new URLSearchParams(window.location.search).has("payment_intent") && existing.paymentStatus === "requires_payment") {
            try {
              existing = await request("rentalPaymentAuthorized", { method: "PATCH", body: JSON.stringify({ orderId: resumeId }) });
            } catch (cause) { setError(cause.message); }
            if (cancelled) return;
          }
          setOrder(existing);
          if (["rejected", "cancelled"].includes(existing.status)) setStep("closed");
          else if (existing.status !== "pending" || existing.renterVerifiedAt) setStep("success");
          else if (existing.paymentStatus === "authorized" || existing.paymentStatus === "captured") setStep("identity");
          else if (existing.contractSignedAt) {
            const config = await request("paymentConfig");
            if (cancelled) return;
            setPublishableKey(config.publishableKey || "");
            setStep("payment");
          } else setStep("contract");
        }
      } catch (cause) {
        if (cancelled) return;
        if (cause.status === 401) setAuthState("guest");
        else { setAuthState("signed-in"); setError(cause.message); }
      }
    }
    initialize();
    return () => { cancelled = true; };
  }, [loadError, productId, offerId, setError]);

  function changeMode(value) {
    setMode(value); setStartDate(""); setEndDate(""); setAvailability(null); setError("");
  }

  async function checkAvailability() {
    setError("");
    if (offer && (mode !== offer.rentalMode || startDate !== String(offer.startDate).slice(0, 10))) { setError("Perioada ofertei nu poate fi schimbată."); return; }
    if (!startDate || !finalEnd || startDate < minimumDate || finalEnd < startDate) {
      setError("Alege o dată validă pentru închiriere."); return;
    }
    if (mode === "hour" && selectedMinutes <= 0) {
      setError("Ora returului trebuie să fie după ora ridicării."); return;
    }
    if (subtotal <= 0 || (mode === "hour" && (pickupTime < (product.pickupTime || "00:00") || returnTime > (product.returnTime || "23:59")))) {
      setError("Prețul sau orele alese nu sunt valide pentru acest anunț."); return;
    }
    if (mode === "hour" && startDate === today && pickupTime <= new Date().toTimeString().slice(0, 5)) {
      setError("Ora de ridicare trebuie să fie în viitor."); return;
    }
    setBusy("availability");
    try {
      const query = new URLSearchParams({ productId, from: startDate, to: plusDays(finalEnd, 2) });
      const data = await request(`rentalAvailability?${query}`);
      const unavailable = new Set(data.unavailableDates || []);
      let free = true;
      if (mode === "hour") {
        const selectedStart = Date.parse(`${startDate}T${pickupTime}:00Z`);
        const selectedEnd = Date.parse(`${startDate}T${returnTime}:00Z`) + 3600000;
        free = !(data.manualBlocks || []).some((block) => block.startDate <= startDate && startDate < block.endDate);
        const overlaps = (data.reservations || []).filter((reservation) => {
          const from = Date.parse(reservation.occupiedFrom);
          const to = Date.parse(reservation.occupiedUntil);
          return from < selectedEnd && to > selectedStart;
        }).length;
        free = free && overlaps < (Number(product.stockQuantity) || 1);
      } else {
        for (let date = startDate; date < (finalEnd === startDate ? plusDays(startDate, 1) : finalEnd); date = plusDays(date, 1)) {
          if (unavailable.has(date)) { free = false; break; }
        }
      }
      setAvailability({ free, checked: true });
      if (!free) setError("Produsul nu este disponibil în perioada aleasă.");
      else setStep("contract");
    } catch (cause) { setError(cause.message); }
    finally { setBusy(""); }
  }

  async function createAndSign() {
    if (!signature) { setError("Semnează contractul înainte de a continua."); return; }
    setBusy("contract"); setError("");
    try {
      const config = await request("paymentConfig");
      if (!config.publishableKey) throw new Error("Plata Stripe nu este configurată.");
      let currentOrder = order;
      if (!currentOrder) {
        if (!availability?.free) throw new Error("Verifică din nou disponibilitatea.");
        const position = product.availabilityScope === "national" ? null : await currentPosition();
        if (offer?.status === "accepted") await request("offerClaim", { method: "PATCH", body: JSON.stringify({ id: idOf(offer) }) });
        currentOrder = await request("rentalCreate", { method: "POST", body: JSON.stringify({ productId, startDate, endDate: finalEnd, rentalMode: mode, pickupTime, returnTime, ...(offer ? { negotiatedSubtotal: offer.amount, offerId: idOf(offer) } : {}), ...position }) });
        setOrder(currentOrder);
        window.history.replaceState({}, "", `${window.location.pathname}?orderId=${encodeURIComponent(idOf(currentOrder))}`);
      }
      const pdf = await buildRentalContractPdf({ product, order: currentOrder, renter: user, signatureDataUrl: signature });
      let binary = "";
      for (let index = 0; index < pdf.length; index += 32768) binary += String.fromCharCode(...pdf.slice(index, index + 32768));
      currentOrder = await request("contractUpload", { method: "POST", body: JSON.stringify({ orderId: idOf(currentOrder), pdfBase64: btoa(binary) }) });
      setOrder(currentOrder);
      setPublishableKey(config.publishableKey);
      setStep("payment");
    } catch (cause) { setError(cause.message); }
    finally { setBusy(""); }
  }

  async function authorizePayment() {
    setBusy("authorize"); setError("");
    try {
      const updated = await request("rentalPaymentAuthorized", { method: "PATCH", body: JSON.stringify({ orderId }) });
      setOrder(updated); setStep("identity");
    } catch (cause) { setError(cause.message); }
    finally { setBusy(""); }
  }

  async function checkIdentity() {
    setBusy("identity"); setError("");
    try {
      const status = await request("identityStatus");
      setIdentity(status);
      if (status.identityVerified) {
        const updated = await request("rentalRenterReady", { method: "PATCH", body: JSON.stringify({ orderId }) });
        setOrder(updated); setStep("success");
      }
    } catch (cause) { setError(cause.message); }
    finally { setBusy(""); }
  }

  async function startIdentity() {
    const tab = window.open("about:blank", "_blank");
    if (tab) tab.opener = null;
    setBusy("identityStart"); setError("");
    try {
      const result = await request("identityStart", { method: "POST", body: "{}" });
      if (result.verified) { tab?.close(); await checkIdentity(); return; }
      if (!result.url) { tab?.close(); setIdentity({ processing: true }); return; }
      const url = new URL(result.url);
      if (url.protocol !== "https:" || (url.hostname !== "stripe.com" && !url.hostname.endsWith(".stripe.com"))) throw new Error("Linkul de verificare nu este valid.");
      if (tab) tab.location.replace(url.href);
      else setIdentityUrl(url.href);
    } catch (cause) { tab?.close(); setError(cause.message); }
    finally { setBusy(""); }
  }

  if (loadError) return <><PublicHeader current="/" /><main className="mx-auto max-w-3xl px-5 pb-24 pt-40 text-center">Nu am putut încărca anunțul. <Link className="text-[#30578F]" href="/">Înapoi la anunțuri</Link></main></>;
  const image = Array.isArray(product.images) ? product.images.find((item) => item?.url && item.type !== "video")?.url : null;
  const accountUrl = `/account?returnTo=${encodeURIComponent(`/inchiriaza/${encodeURIComponent(product.slug)}?${offerId ? `offerId=${encodeURIComponent(offerId)}` : `mode=${mode}`}`)}`;

  return <>
    <Head><title>{`Închiriază ${product.title} | PINLEND`}</title></Head>
    <PublicHeader current="/" />
    <main className="mx-auto max-w-7xl px-5 pb-24 pt-28 md:px-8">
      <Link className="mb-6 inline-flex items-center gap-2 text-sm font-bold text-[#30578F]" href={`/anunt/${encodeURIComponent(product.slug)}`}><span aria-hidden="true" className="material-symbols-outlined text-[18px]">arrow_back</span>Înapoi la anunț</Link>
      <p className="font-mono text-xs uppercase tracking-widest text-[#30578F]">Închiriere</p>
      <h1 className="mt-3 font-display text-4xl font-extrabold md:text-5xl">Finalizează închirierea</h1>
      <div className="mt-8 grid gap-8 lg:grid-cols-[minmax(0,1fr)_360px]">
        <div className="min-w-0 rounded-[20px] bg-white p-6 shadow-sm md:p-8">
          {authState === "loading" ? <BrandLoader className="py-16" label="Se încarcă contul..." /> : authState === "guest" ? <div><h2 className="text-2xl font-extrabold">Conectează-te pentru a continua</h2><p className="mt-3 text-[#434750]">Perioada, contractul și plata vor fi salvate în contul tău.</p><Link className="mt-6 inline-flex rounded-full bg-[#30578F] px-6 py-3 font-bold text-white" href={accountUrl}>Autentifică-te sau creează cont</Link></div> : <>
            <div className="mb-8 flex flex-wrap gap-2 text-xs font-bold uppercase tracking-wider">{[["period", "1. Perioadă"], ["contract", "2. Contract"], ["payment", "3. Plată"], ["identity", "4. Identitate"], ["success", "5. Gata"]].map(([value, label]) => <span className={`rounded-full px-3 py-2 ${step === value ? "bg-[#30578F] text-white" : "bg-[#E7F0FD] text-[#30578F]"}`} key={value}>{label}</span>)}</div>
            
            {step === "period" && <section>
              <h2 className="text-2xl font-extrabold">Alege perioada</h2>
              <p className="mt-2 text-sm text-[#434750]">Disponibilitatea este verificată înainte de a crea cererea.</p>
              {offer && <p className="mt-4 rounded-xl bg-[#E7F0FD] p-4 text-sm font-bold text-[#30578F]">Ofertă acceptată: {ron(offer.amount)} pentru perioada stabilită în chat.</p>}
              <ToggleGroup aria-label="Durata închirierii" className="mt-6 flex-wrap gap-2" disabled={Boolean(offer)} onValueChange={(value) => { if (value) changeMode(value); }} spacing={2} type="single" value={mode}>
                {modes.map((value) => <ToggleGroupItem className="h-10 min-w-16 rounded-full bg-[#E7F0FD] px-5 text-sm font-bold text-[#30578F] hover:bg-[#D7E6FA] hover:text-[#30578F] data-[state=on]:bg-[#30578F] data-[state=on]:text-white data-[state=on]:hover:bg-[#30578F] data-[state=on]:hover:text-white" key={value} value={value}>{modeLabel[value] || value}</ToggleGroupItem>)}
              </ToggleGroup>
              <div className="mt-6 grid gap-4 sm:grid-cols-2">
                <RentalDateField disabled={Boolean(offer)} label="Data ridicării" min={minimumDate} onChange={(value) => { setStartDate(value); if (endDate && endDate < value) setEndDate(""); setAvailability(null); setError(""); }} value={startDate} />
                {mode === "day" ? <RentalDateField disabled={Boolean(offer)} label="Data returului" min={startDate || minimumDate} onChange={(value) => { setEndDate(value); setAvailability(null); setError(""); }} value={endDate} /> : mode === "month" && startDate ? <div className="text-sm font-bold">Data returului<p className="account-input font-normal">{new Intl.DateTimeFormat("ro-RO", { day: "2-digit", month: "long", year: "numeric" }).format(new Date(`${finalEnd}T12:00:00`))}</p></div> : null}
              </div>
              {mode === "hour" && <>
                <div className="mt-4 grid gap-4 sm:grid-cols-2"><RentalTimeField disabled={Boolean(offer)} label="Ora ridicării" max={product.returnTime || "23:59"} min={product.pickupTime || "00:00"} onChange={(value) => { setPickupTime(value); setAvailability(null); setError(""); }} value={pickupTime} /><RentalTimeField disabled={Boolean(offer)} label="Ora returului" max={product.returnTime || "23:59"} min={product.pickupTime || "00:00"} onChange={(value) => { setReturnTime(value); setAvailability(null); setError(""); }} value={returnTime} /></div>
                {startDate === today && pickupTime <= new Date().toTimeString().slice(0, 5) && <p className="mt-3 text-sm text-red-700">Ora de ridicare a trecut deja astăzi. Alege o oră viitoare sau altă zi.</p>}
                {selectedMinutes > 0 && <div className="mt-5 rounded-xl bg-[#F5F8FD] p-4 text-sm text-[#30578F]">
                  <p><strong>Durată: {Math.floor(selectedMinutes / 60)} h {selectedMinutes % 60} min</strong> · {offer ? <>Preț negociat: <strong>{ron(offer.amount)}</strong>.</> : <>Se taxează {hours} {hours === 1 ? "oră" : "ore"} × {ron(hourlyPrice)} = <strong>{ron(calculatedSubtotal)}</strong>.</>}</p>
                  <p className="mt-1 text-xs text-[#526680]">După retur, păstrăm o oră pentru pregătirea produsului; această oră nu se taxează.</p>
                </div>}
              </>}
              <Button className="mt-8 h-12 rounded-full px-7 text-base font-bold" disabled={Boolean(busy) || product.isAvailable === false} onClick={checkAvailability} type="button">{busy === "availability" ? "Se verifică..." : "Continuă la contract"}</Button>
              {product.isAvailable === false && <p className="mt-3 text-sm text-red-700">Anunțul este momentan indisponibil.</p>}
            </section>}
            {step === "contract" && <section>
              <h2 className="text-2xl font-extrabold">Rezumat și contract</h2>
              <p className="mt-3 text-sm text-[#434750]">{order ? "Cererea a fost creată. Semnează contractul pentru a continua." : `Perioada ${startDate} – ${finalEnd} este disponibilă.`}</p>
              <div className="mt-6 space-y-3 rounded-xl bg-[#F5F6F8] p-5 text-sm"><p>Proprietar: <strong>{product.ownerName || "Proprietar PINLEND"}</strong></p><p>Locatar: <strong>{user?.fullName || user?.email}</strong></p><p>Predare: <strong>{pickupTime}</strong> · Retur: <strong>{returnTime}</strong></p><p>Subtotal: <strong>{ron(order?.subtotal ?? subtotal)}</strong> · Taxă serviciu: <strong>{ron(order?.serviceFee ?? serviceFee)}</strong></p><p>Garanție: <strong>{ron(order?.deposit ?? product.deposit)}</strong> · Total: <strong>{ron(order?.total ?? total)}</strong></p></div>
              <div className="mt-6 space-y-4 text-sm leading-6 text-[#434750]"><p><strong>Termeni generali.</strong> Proprietarul oferă bunul spre folosință temporară pentru perioada indicată. Documentul PDF este un model generat de PINLEND.</p><p><strong>Predare și retur.</strong> Bunul se returnează la timp, în starea primită, cu excepția uzurii normale.</p><p><strong>Responsabilitate și garanție.</strong> Deteriorarea, pierderea sau întârzierea poate duce la reținerea garanției. Detaliile sunt consemnate în contractul semnat.</p></div>
              <h3 className="mt-7 mb-3 font-extrabold">Semnătura locatarului</h3><SignaturePad onChange={setSignature} />
              <div className="mt-6 flex flex-wrap gap-3">{!order && <button className="rounded-full border border-[#30578F] px-6 py-3 font-bold text-[#30578F]" onClick={() => setStep("period")} type="button">Schimbă perioada</button>}<button className="rounded-full bg-[#30578F] px-7 py-3 font-bold text-white disabled:opacity-50" disabled={Boolean(busy) || !signature} onClick={createAndSign} type="button">{busy === "contract" ? "Se pregătește..." : "Semnează și continuă la plată"}</button></div>
            </section>}
            {step === "payment" && <section><h2 className="text-2xl font-extrabold">Autorizează plata</h2><p className="mt-3 text-sm leading-6 text-[#434750]">Stripe autorizează {ron(order?.total)}. Plata este confirmată de backend după autorizare; cererea ajunge la proprietar după verificarea identității.</p>{publishableKey && order?.stripePaymentClientSecret ? <PaymentForm clientSecret={order.stripePaymentClientSecret} onAuthorized={authorizePayment} onError={setCheckoutError} orderId={orderId} publishableKey={publishableKey} /> : <p className="mt-5 text-red-700">Plata nu este disponibilă. Reîncarcă pagina pentru a încerca din nou.</p>}</section>}
            {step === "identity" && <section><h2 className="text-2xl font-extrabold">Verifică identitatea</h2><p className="mt-3 leading-6 text-[#434750]">Plata este autorizată. Verifică actul și selfie-ul prin Stripe Identity, apoi trimite cererea proprietarului.</p>{identity?.processing && <p className="mt-4 rounded-xl bg-amber-50 p-4 text-sm text-amber-800">Verificarea este în curs. Revino peste câteva momente.</p>}{identityUrl && <a className="mt-4 inline-block font-bold text-[#30578F] underline" href={identityUrl} rel="noopener noreferrer" target="_blank">Deschide linkul Stripe Identity</a>}<div className="mt-7 flex flex-wrap gap-3"><button className="rounded-full bg-[#30578F] px-6 py-3 font-bold text-white disabled:opacity-50" disabled={Boolean(busy)} onClick={startIdentity} type="button">Deschide verificarea</button><button className="rounded-full border border-[#30578F] px-6 py-3 font-bold text-[#30578F] disabled:opacity-50" disabled={Boolean(busy)} onClick={checkIdentity} type="button">{busy === "identity" ? "Se verifică..." : "Am terminat verificarea"}</button></div></section>}
            {step === "success" && <section><span aria-hidden="true" className="material-symbols-outlined text-5xl text-green-600">check_circle</span><h2 className="mt-4 text-3xl font-extrabold">Cererea este în contul tău</h2><p className="mt-3 text-[#434750]">Poți urmări starea închirierii în secțiunea „Închirieri”. Proprietarul va vedea cererea după verificarea identității.</p><Link className="mt-7 inline-flex rounded-full bg-[#30578F] px-6 py-3 font-bold text-white" href="/account?section=rentals">Vezi închirierile mele</Link></section>}
            {step === "closed" && <section><h2 className="text-2xl font-extrabold">Această cerere este închisă</h2><p className="mt-3 text-[#434750]">Poți vedea detaliile în istoricul închirierilor sau poți începe o cerere nouă.</p><Link className="mt-6 inline-flex rounded-full bg-[#30578F] px-6 py-3 font-bold text-white" href="/account?section=rentals">Vezi istoricul</Link></section>}
          </>}
        </div>
        <aside className="h-fit rounded-[20px] bg-white p-5 shadow-sm lg:sticky lg:top-6">{image && <img alt={product.title} className="aspect-[4/3] w-full rounded-xl object-cover" src={image} />}<h2 className="mt-5 font-display text-2xl font-extrabold">{product.title}</h2><p className="mt-2 text-sm text-[#434750]">{product.city} · {product.category}</p><div className="mt-6 border-t border-black/10 pt-5 text-sm"><div className="flex justify-between"><span>Închiriere</span><strong>{ron(order?.subtotal ?? subtotal)}</strong></div><div className="mt-3 flex justify-between"><span>Taxă serviciu</span><strong>{ron(order?.serviceFee ?? serviceFee)}</strong></div><div className="mt-3 flex justify-between"><span>Garanție</span><strong>{ron(order?.deposit ?? product.deposit)}</strong></div><div className="mt-5 flex justify-between border-t border-black/10 pt-4 text-lg font-extrabold"><span>Total</span><span>{ron(order?.total ?? total)}</span></div></div></aside>
      </div>
    </main>
  </>;
}
