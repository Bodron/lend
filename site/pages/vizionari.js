import Head from "next/head";
import { useToastNotice } from "../lib/useToastNotice";
import { RentalDateTimeField } from "../components/RentalPeriodFields";
import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/router";
import { loadStripe } from "@stripe/stripe-js";
import AppHeader from "../components/AppHeader";
import { accountRequest, requireLogin } from "../lib/accountRequest";
import { useToastError } from "../lib/useToastError";
import { useConfirmAction } from "../components/ConfirmActionProvider";

const activeStatuses = new Set(["requested", "counter_proposed", "awaiting_payment", "awaiting_verification", "refund_pending", "confirmed"]);
const labels = {
  requested: "Cerere trimisă", counter_proposed: "Altă oră propusă", awaiting_payment: "Așteaptă plata",
  awaiting_verification: "Așteaptă verificarea", refund_pending: "Rambursare în curs",
  confirmed: "Confirmată", completed: "Finalizată", cancelled: "Anulată", rejected: "Respinsă",
};
const validId = (id) => typeof id === "string" && /^[a-f\d]{24}$/i.test(id);
const displayDate = (value) => value ? new Date(value).toLocaleString("ro-RO", { dateStyle: "medium", timeStyle: "short" }) : "—";
const localDateTime = (value) => new Date(value - new Date(value).getTimezoneOffset() * 60000).toISOString().slice(0, 16);

function Payment({ viewingId, clientSecret, publishableKey, onPaid, onError }) {
  const mountRef = useRef(null);
  const [stripeState, setStripeState] = useState(null);
  const [busy, setBusy] = useState(false);
  useEffect(() => {
    let cancelled = false;
    let element;
    loadStripe(publishableKey).then((stripe) => {
      if (!stripe || cancelled) return;
      const elements = stripe.elements({ clientSecret });
      element = elements.create("payment");
      element.mount(mountRef.current);
      setStripeState({ stripe, elements });
    }).catch((cause) => { if (!cancelled) onError(cause.message); });
    return () => { cancelled = true; element?.destroy(); };
  }, [clientSecret, publishableKey, onError]);
  async function pay(event) {
    event.preventDefault();
    if (!stripeState || busy) return;
    setBusy(true);
    try {
      const result = await stripeState.stripe.confirmPayment({
        elements: stripeState.elements,
        confirmParams: { return_url: `${window.location.origin}/vizionari?paymentId=${viewingId}` },
        redirect: "if_required",
      });
      if (result.error) throw new Error(result.error.message);
      await onPaid(viewingId);
    } catch (cause) { onError(cause.message); }
    finally { setBusy(false); }
  }
  return <form className="mt-4" onSubmit={pay}><div ref={mountRef} /><button className="account-button mt-4" disabled={!stripeState || busy} type="submit">{busy ? "Se procesează..." : "Plătește vizionarea"}</button></form>;
}

export default function ViewingsPage() {
  const confirmAction = useConfirmAction();
  const router = useRouter();
  const [user, setUser] = useState(null);
  const [items, setItems] = useState([]);
  const [startsAt, setStartsAt] = useState("");
  const [minimumStartAt] = useState(() => localDateTime(Date.now() + 3600000));
  const [proposal, setProposal] = useState({});
  const [payment, setPayment] = useState(null);
  const [busy, setBusy] = useState("");
  const [, setError] = useToastError();
  const setNotice = useToastNotice();
  const productId = router.query.productId;
  const myActive = items.some((item) => item.productId === productId && item.visitorId === (user?.id || user?._id) && activeStatuses.has(item.status));

  async function refresh() {
    const result = await accountRequest("viewingList");
    setItems(Array.isArray(result) ? result : []);
  }
  useEffect(() => {
    let active = true;
    Promise.all([accountRequest("me"), accountRequest("viewingList")]).then(([profile, result]) => {
      if (!active) return;
      setUser(profile); setItems(Array.isArray(result) ? result : []);
    }).catch((cause) => { if (active && !requireLogin(cause, `/vizionari${window.location.search}`)) setError(cause.message); });
    return () => { active = false; };
  }, [setError]);
  useEffect(() => {
    if (!router.isReady || !validId(router.query.paymentId)) return;
    accountRequest("viewingPaymentConfirmed", { method: "PATCH", body: JSON.stringify({ id: router.query.paymentId }) })
      .then(() => refresh()).catch((cause) => setError(cause.message));
  }, [router.isReady, router.query.paymentId, setError]);

  async function run(action, id, body = {}) {
    setBusy(id); setError(""); setNotice("");
    try {
      await accountRequest(action, { method: action === "viewingPayment" ? "POST" : "PATCH", body: JSON.stringify({ id, ...body }) });
      await refresh();
      setNotice("Starea vizionării a fost actualizată.");
    } catch (cause) { setError(cause.message); }
    finally { setBusy(""); }
  }

  async function requestViewing(event) {
    event.preventDefault();
    if (!validId(productId)) return;
    if (!startsAt || startsAt < minimumStartAt) {
      setError("Alege o dată și o oră viitoare pentru vizionare.");
      return;
    }
    setBusy("new"); setError("");
    try {
      await accountRequest("viewingCreate", { method: "POST", body: JSON.stringify({ productId, startsAt: new Date(startsAt).toISOString() }) });
      setStartsAt(""); await refresh(); setNotice("Cererea a fost trimisă proprietarului. Nu plătești acum.");
    } catch (cause) { setError(cause.message); }
    finally { setBusy(""); }
  }

  async function startPayment(item) {
    setBusy(item._id); setError("");
    try {
      const [result, config] = await Promise.all([
        accountRequest("viewingPayment", { method: "POST", body: JSON.stringify({ id: item._id }) }),
        accountRequest("paymentConfig"),
      ]);
      if (result.confirmed) { await refresh(); return; }
      if (!result.clientSecret || !config.publishableKey) throw new Error("Plata nu este disponibilă acum.");
      setPayment({ viewingId: item._id, clientSecret: result.clientSecret, publishableKey: config.publishableKey });
    } catch (cause) { setError(cause.message); }
    finally { setBusy(""); }
  }

  async function verifyIdentity(item) {
    setBusy(item._id); setError("");
    const tab = window.open("about:blank", "_blank");
    if (tab) tab.opener = null;
    try {
      const result = await accountRequest("identityStart", { method: "POST", body: "{}" });
      if (result.url) {
        const url = new URL(result.url);
        if (url.protocol !== "https:" || !(url.hostname === "stripe.com" || url.hostname.endsWith(".stripe.com"))) throw new Error("Link invalid pentru verificare.");
        if (tab) tab.location.replace(result.url); else window.location.assign(result.url);
        setNotice("Finalizează verificarea în fila Stripe, apoi revino și apasă din nou Verifică identitatea.", "info");
      } else {
        if (tab) tab.close();
        if (result.verified) await run("viewingIdentityConfirmed", item._id);
        else setNotice("Verificarea este în curs. Reîncearcă după ce Stripe o finalizează.", "info");
      }
    } catch (cause) { if (tab) tab.close(); setError(cause.message); }
    finally { setBusy(""); }
  }

  return <>
    <Head><title>Vizionări | PINLEND</title></Head>
    <AppHeader />
    <main className="mx-auto max-w-5xl px-5 py-12 md:px-8"><p className="font-mono text-xs uppercase tracking-widest text-[#30578F]">Locuințe</p><h1 className="mt-3 font-display text-4xl font-extrabold">Vizionări</h1><p className="mt-3 text-[#626977]">Trimiți cererea gratuit. Dacă proprietarul o acceptă, achiți vizionarea aici.</p>
      
      {validId(productId) && user && <form className="account-card mt-8" onSubmit={requestViewing}><h2 className="text-xl font-extrabold">Propune data și ora</h2><p className="mt-2 text-sm text-[#626977]">O singură cerere activă pentru acest anunț.</p><div className="mt-5 flex flex-wrap items-end gap-3"><RentalDateTimeField label="Vizionare" min={minimumStartAt} onChange={setStartsAt} value={startsAt} /><button className="account-button" disabled={busy === "new" || myActive} type="submit">{myActive ? "Vizionare în curs" : "Trimite cererea"}</button></div></form>}
      <div className="mt-8 space-y-4">{items.map((item) => {
        const mine = item.visitorId === (user?.id || user?._id);
        return <article className="account-card" key={item._id}><div className="flex flex-wrap justify-between gap-3"><div><h2 className="text-lg font-extrabold">{item.productTitle}</h2><p className="mt-1 text-sm text-[#626977]">{mine ? "Cererea mea" : `De la ${item.visitorName}`} · {displayDate(item.startsAt)}</p></div><span className="h-fit rounded-full bg-[#E7F0FD] px-4 py-2 text-sm font-bold text-[#30578F]">{labels[item.status] || item.status}</span></div>
          {item.status === "counter_proposed" && <p className="mt-4 text-sm">Proprietarul propune: <strong>{displayDate(item.proposedStartsAt)}</strong></p>}
          <div className="mt-5 flex flex-wrap gap-2">
            {!mine && item.status === "requested" && <><button className="account-button" disabled={busy === item._id} onClick={() => run("viewingAccept", item._id)} type="button">Acceptă</button><button className="account-button-light" disabled={busy === item._id} onClick={() => run("viewingReject", item._id)} type="button">Respinge</button></>}
            {!mine && ["requested", "counter_proposed"].includes(item.status) && <div className="flex items-end gap-2"><RentalDateTimeField label="Altă propunere" onChange={(value) => setProposal({ ...proposal, [item._id]: value })} value={proposal[item._id] || ""} /><button className="account-button-light" disabled={busy === item._id || !proposal[item._id]} onClick={() => run("viewingPropose", item._id, { startsAt: new Date(proposal[item._id]).toISOString() })} type="button">Propune</button></div>}
            {mine && item.status === "counter_proposed" && <><button className="account-button" onClick={() => run("viewingAcceptProposal", item._id)} type="button">Acceptă ora</button><button className="account-button-light" onClick={() => run("viewingDeclineProposal", item._id)} type="button">Refuză ora</button></>}
            {mine && item.status === "awaiting_payment" && item.priceRon > 0 && <button className="account-button" onClick={() => startPayment(item)} type="button">Plătește {item.priceRon + (item.serviceFeeRon || 0)} RON</button>}
            {item.status === "awaiting_verification" && <button className="account-button-light" onClick={() => verifyIdentity(item)} type="button">Verifică identitatea</button>}
            {!mine && item.status === "confirmed" && new Date(item.startsAt) <= new Date() && <button className="account-button" onClick={() => run("viewingComplete", item._id)} type="button">Finalizează vizionarea</button>}
            {["requested", "counter_proposed", "awaiting_payment", "confirmed", "awaiting_verification"].includes(item.status) && (!mine || item.status !== "confirmed" || item.priceRon === 0) && <button className="account-button-light" onClick={async () => { if (await confirmAction({ title: "Anulezi vizionarea?", description: "Cererea de vizionare va fi anulată.", confirmLabel: "Anulează vizionarea", destructive: true })) run("viewingCancel", item._id); }} type="button">Anulează</button>}
          </div>
          {payment?.viewingId === item._id && <Payment clientSecret={payment.clientSecret} onError={setError} onPaid={async (id) => { await run("viewingPaymentConfirmed", id); setPayment(null); }} publishableKey={payment.publishableKey} viewingId={item._id} />}
        </article>;
      })}{user && items.length === 0 && <p className="account-card text-[#626977]">Nu ai vizionări încă.</p>}</div>
    </main>
  </>;
}
