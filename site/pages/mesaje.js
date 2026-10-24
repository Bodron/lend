import Head from "next/head";
import FormSelect from "../components/FormSelect";
import { Input } from "../components/ui/input";
import { RentalDateField } from "../components/RentalPeriodFields";
import { Textarea } from "../components/ui/textarea";
import Link from "next/link";
import { useRouter } from "next/router";
import { useCallback, useEffect, useRef, useState } from "react";
import AppHeader from "../components/AppHeader";
import BrandLoader from "../components/BrandLoader";
import { useToastError } from "../lib/useToastError";
import UserAvatar from "../components/UserAvatar";
import { useConfirmAction } from "../components/ConfirmActionProvider";

const validId = (value) => typeof value === "string" && /^[a-f\d]{24}$/i.test(value);

async function request(action, options = {}) {
  const response = await fetch(`/api/account/${action}`, {
    credentials: "same-origin",
    cache: "no-store",
    ...options,
    headers: { ...(options.body ? { "Content-Type": "application/json" } : {}), ...options.headers },
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message = Array.isArray(data.message) ? data.message.join(" ") : data.message;
    const error = new Error(message || "Nu am putut încărca mesajele.");
    error.status = response.status;
    throw error;
  }
  return data;
}

function threadKey(thread) {
  return `${thread.productId}:${thread.roommateInterestId || ""}:${thread.participantId || ""}`;
}

function threadUrl(thread) {
  const query = new URLSearchParams({ productId: thread.productId });
  if (thread.roommateInterestId) query.set("roommateInterestId", thread.roommateInterestId);
  if (thread.participantId) query.set("participantId", thread.participantId);
  return `/mesaje?${query}`;
}

function threadAction(thread) {
  const query = new URLSearchParams({ productId: thread.productId });
  if (thread.roommateInterestId) query.set("roommateInterestId", thread.roommateInterestId);
  if (thread.participantId) query.set("participantId", thread.participantId);
  return `messageThread?${query}`;
}

function time(value) {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  return new Intl.DateTimeFormat("ro-RO", {
    day: "numeric", month: "short", hour: "2-digit", minute: "2-digit",
  }).format(date);
}

function preview(body) {
  if (typeof body !== "string") return "";
  if (body.startsWith("@@roommate_proposal_accepted:")) return "Propunere de coleg acceptată";
  if (body.startsWith("@@roommate_proposal:")) return "Propunere de coleg de apartament";
  return body;
}

export default function MessagesPage() {
  const confirmAction = useConfirmAction();
  const router = useRouter();
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [threads, setThreads] = useState([]);
  const [thread, setThread] = useState(null);
  const [draft, setDraft] = useState("");
  const [sending, setSending] = useState(false);
  const [offerForm, setOfferForm] = useState(false);
  const [offerDraft, setOfferDraft] = useState({ amount: "", startDate: "", endDate: "", rentalMode: "day" });
  const [, setError] = useToastError();
  const bottomRef = useRef(null);

  const loadThreads = useCallback(async () => {
    const result = await request("messageThreads");
    setThreads(Array.isArray(result) ? result : []);
  }, []);

  const productId = router.query.productId;
  const roommateInterestId = router.query.roommateInterestId;
  const participantId = router.query.participantId;
  const selected = router.isReady && validId(productId) && (!roommateInterestId || validId(roommateInterestId)) && (!participantId || validId(participantId))
    ? { productId, roommateInterestId: roommateInterestId || null, participantId: participantId || null }
    : null;
  const selectedKey = selected && threadKey(selected);
  const visibleThread = thread?.key === selectedKey ? thread.data : null;

  useEffect(() => {
    let cancelled = false;
    Promise.all([request("me"), request("messageThreads")])
      .then(([profile, items]) => {
        if (cancelled) return;
        setUser(profile);
        setThreads(Array.isArray(items) ? items : []);
      })
      .catch((cause) => {
        if (cancelled) return;
        if (cause.status === 401) {
          const returnTo = `${window.location.pathname}${window.location.search}`;
          router.replace(`/account?returnTo=${encodeURIComponent(returnTo)}`);
        } else setError(cause.message);
      })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [router, setError]);

  useEffect(() => {
    if (!user || !selected) return;
    let cancelled = false;
    const update = async (showError) => {
      try {
        const result = await request(threadAction(selected));
        if (!cancelled) setThread({ key: selectedKey, data: result });
      } catch (cause) {
        if (!cancelled && showError) setError(cause.message);
      }
    };
    update(true);
    const timer = window.setInterval(() => {
      if (document.visibilityState === "visible") {
        update(false);
        loadThreads().catch(() => {});
      }
    }, 5000);
    return () => { cancelled = true; window.clearInterval(timer); };
  }, [user, selectedKey, loadThreads]); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (!user || selectedKey) return;
    const timer = window.setInterval(() => {
      if (document.visibilityState === "visible") loadThreads().catch(() => {});
    }, 5000);
    return () => window.clearInterval(timer);
  }, [user, selectedKey, loadThreads]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth", block: "end" });
  }, [visibleThread?.messages?.length]);

  async function send(event) {
    event.preventDefault();
    const body = draft.trim();
    if (!selected || !body || sending) return;
    setSending(true);
    setError("");
    try {
      const message = await request("messageSend", {
        method: "POST",
        body: JSON.stringify({ productId: selected.productId, ...(selected.roommateInterestId ? { roommateInterestId: selected.roommateInterestId } : {}), ...(selected.participantId ? { recipientId: selected.participantId } : {}), body }),
      });
      setDraft("");
      setThread((previous) => previous?.key === selectedKey ? {
        ...previous,
        data: {
          ...previous.data,
          messages: previous.data.messages.some((item) => item._id === message._id)
            ? previous.data.messages : [...previous.data.messages, message],
        },
      } : previous);
      await loadThreads();
    } catch (cause) {
      setError(cause.message);
    } finally { setSending(false); }
  }

  async function removeThread() {
    if (!selected || !await confirmAction({
      title: "Ștergi conversația?",
      description: "Conversația va fi eliminată din lista ta.",
      confirmLabel: "Șterge conversația",
      destructive: true,
    })) return;
    setError("");
    try {
      const query = new URLSearchParams({ productId: selected.productId });
      if (selected.roommateInterestId) query.set("roommateInterestId", selected.roommateInterestId);
      if (selected.participantId) query.set("participantId", selected.participantId);
      await request(`messageDelete?${query}`, { method: "DELETE" });
      await loadThreads();
      router.push("/mesaje", undefined, { shallow: true });
    } catch (cause) { setError(cause.message); }
  }

  async function updateOffer(action, offerId) {
    setError("");
    try {
      await request(action, { method: "PATCH", body: JSON.stringify({ id: offerId }) });
      setThread({ key: selectedKey, data: await request(threadAction(selected)) });
    } catch (cause) { setError(cause.message); }
  }

  async function createOffer(event) {
    event.preventDefault();
    if (!selected) return;
    if (!offerDraft.startDate || !offerDraft.endDate || offerDraft.endDate < offerDraft.startDate) {
      setError("Alege o perioadă validă pentru ofertă.");
      return;
    }
    setError("");
    try {
      await request("offerCreate", { method: "POST", body: JSON.stringify({
        productId: selected.productId,
        amount: Number(offerDraft.amount),
        startDate: new Date(`${offerDraft.startDate}T00:00:00`).toISOString(),
        endDate: new Date(`${offerDraft.endDate}T00:00:00`).toISOString(),
        rentalMode: offerDraft.rentalMode,
      }) });
      setOfferForm(false);
      setThread({ key: selectedKey, data: await request(threadAction(selected)) });
    } catch (cause) { setError(cause.message); }
  }

  return <>
    <Head><title>Mesaje | PINLEND</title><meta name="description" content="Conversațiile tale PINLEND." /></Head>
    <AppHeader />
    <main className="mx-auto max-w-7xl px-5 pb-16 pt-10 md:px-8">
      <p className="font-mono text-xs uppercase tracking-[0.25em] text-[#30578F]">PINLEND / Conversații</p>
      <h1 className="mt-3 font-display text-4xl font-extrabold md:text-6xl">Mesaje</h1>
      <p className="mt-3 text-[#626977]">Discută direct cu proprietarii și chiriașii. Conversațiile sunt sincronizate cu aplicația mobilă.</p>
      
      {loading ? <BrandLoader className="mt-10 py-16" label="Se încarcă mesajele..." /> : user && <div className="mt-9 grid min-h-[590px] overflow-hidden rounded-[20px] border border-black/10 bg-white shadow-sm md:grid-cols-[310px_minmax(0,1fr)]">
        <aside className={`border-b border-black/10 md:border-b-0 md:border-r ${selected ? "hidden md:block" : "block"}`}>
          <div className="flex items-center justify-between border-b border-black/10 px-5 py-4"><h2 className="font-extrabold">Conversații</h2><button aria-label="Actualizează conversațiile" className="text-[#30578F]" onClick={() => loadThreads().catch((cause) => setError(cause.message))} type="button"><span className="material-symbols-outlined">refresh</span></button></div>
          {threads.length === 0 ? <p className="p-5 text-sm text-[#626977]">Nu ai încă mesaje. Deschide un anunț și scrie proprietarului.</p> : <div className="max-h-[610px] overflow-y-auto">{threads.map((item) => <Link className={`block border-b border-black/5 p-4 transition-colors hover:bg-[#F2F6FC] ${threadKey(item) === selectedKey ? "bg-[#E7F0FD]" : ""}`} href={threadUrl(item)} key={threadKey(item)}>
            <div className="flex items-start gap-3">
              <UserAvatar className="size-11" user={{ fullName: item.participantName || "P", avatarUrl: item.participantAvatarUrl }} />
              <div className="min-w-0 flex-1"><div className="flex items-center justify-between gap-2"><p className="truncate font-extrabold">{item.participantName || "Utilizator"}</p>{item.unreadCount > 0 && <span className="rounded-full bg-[#30578F] px-2 py-0.5 text-xs font-bold text-white">{item.unreadCount}</span>}</div><p className="mt-1 truncate text-xs text-[#626977]">{item.productTitle || "Anunț"}</p><p className="mt-2 truncate text-sm text-[#434750]">{preview(item.latestMessage?.body)}</p></div>
            </div>
          </Link>)}</div>}
        </aside>
        <section className={`${selected ? "flex" : "hidden md:flex"} min-h-[590px] flex-col`} aria-label="Conversație">
          {!selected ? <div className="m-auto px-6 text-center text-[#626977]"><span className="material-symbols-outlined text-5xl text-[#30578F]">forum</span><p className="mt-3 font-bold">Alege o conversație sau scrie din pagina unui anunț.</p></div> : <>
            <div className="flex items-center justify-between gap-3 border-b border-black/10 px-4 py-4 md:px-6">
              <div className="flex min-w-0 items-center gap-3"><Link aria-label="Înapoi la conversații" className="md:hidden" href="/mesaje"><span className="material-symbols-outlined">arrow_back</span></Link><div className="min-w-0"><p className="truncate font-extrabold">{visibleThread?.participantName || "Conversație"}</p><p className="truncate text-xs text-[#626977]">{visibleThread?.productTitle || "Anunț PINLEND"}</p></div></div>
              <div className="flex items-center gap-3">{visibleThread && !selected.roommateInterestId && visibleThread.ownerId !== (user._id || user.id) && <button className="text-sm font-bold text-[#30578F]" onClick={() => setOfferForm(!offerForm)} type="button">Propune preț</button>}<button aria-label="Șterge conversația" className="text-[#626977] hover:text-red-700" onClick={removeThread} type="button"><span className="material-symbols-outlined">delete</span></button></div>
            </div>
            {offerForm && <form className="grid items-end gap-2 border-b border-black/10 bg-[#F7F9FC] p-4 sm:grid-cols-4" onSubmit={createOffer}><RentalDateField label="Până la" min={offerDraft.startDate} onChange={(value) => setOfferDraft((current) => ({ ...current, endDate: value }))} value={offerDraft.endDate} /><FormSelect aria-label="Tipul închirierii" className="account-input mt-0" onChange={(event) => setOfferDraft({ ...offerDraft, rentalMode: event.target.value })} value={offerDraft.rentalMode}><option value="hour">Oră</option><option value="day">Zi</option><option value="month">Lună</option></FormSelect><button className="account-button sm:col-span-4" type="submit">Trimite oferta</button></form>}
            <div className="flex-1 space-y-4 overflow-y-auto bg-[#FAFBFD] px-4 py-6 md:max-h-[540px] md:px-6">
              {!visibleThread ? <BrandLoader className="py-12" label="Se încarcă conversația..." /> : visibleThread.ownerId === (user._id || user.id) && !selected.participantId ? <p className="text-center text-sm text-[#626977]">Alege conversația din listă pentru a răspunde persoanei potrivite.</p> : visibleThread.messages?.length ? visibleThread.messages.map((message) => {
                const mine = message.senderId === (user._id || user.id);
                return <div className={`flex ${mine ? "justify-end" : "justify-start"}`} key={message._id || message.id}>
                  <div className={`max-w-[85%] rounded-2xl px-4 py-3 shadow-sm md:max-w-[70%] ${mine ? "rounded-br-sm bg-[#30578F] text-white" : "rounded-bl-sm bg-white text-[#1B1B1B]"}`}><p className="whitespace-pre-wrap break-words text-sm leading-6">{preview(message.body)}</p><p className={`mt-1 text-right text-[11px] ${mine ? "text-white/70" : "text-[#626977]"}`}>{time(message.createdAt)}</p></div>
                </div>;
              }) : <p className="text-center text-sm text-[#626977]">Niciun mesaj încă. Scrie primul mesaj.</p>}
              {visibleThread?.offers?.map((offer) => <article className="rounded-2xl border border-[#30578F]/20 bg-white p-4" key={offer._id}><p className="font-bold">Ofertă: {offer.amount} RON</p><p className="mt-1 text-xs text-[#626977]">{String(offer.startDate).slice(0, 10)} – {String(offer.endDate).slice(0, 10)} · {offer.rentalMode} · {offer.status}</p>{offer.recipientId === (user._id || user.id) && offer.status === "pending" && <div className="mt-3 flex gap-2"><button className="account-button" onClick={() => updateOffer("offerAccept", offer._id)} type="button">Acceptă</button><button className="account-button-light" onClick={() => updateOffer("offerReject", offer._id)} type="button">Respinge</button></div>}{offer.senderId === (user._id || user.id) && offer.status === "accepted" && visibleThread.productSlug && <Link className="account-button mt-3 inline-block" href={`/inchiriaza/${encodeURIComponent(visibleThread.productSlug)}?offerId=${encodeURIComponent(offer._id)}`}>Continuă către plată</Link>}</article>)}
              <div ref={bottomRef} />
            </div>
            <form className="flex items-end gap-3 border-t border-black/10 bg-white p-4 md:p-5" onSubmit={send}><label className="sr-only" htmlFor="message-draft">Mesaj</label><Textarea className="min-h-12 max-h-36 flex-1 resize-y rounded-2xl border border-black/15 px-4 py-3 text-sm outline-none focus:border-[#30578F]" id="message-draft" maxLength={2000} onChange={(event) => setDraft(event.target.value)} onKeyDown={(event) => { if (event.key === "Enter" && !event.shiftKey) { event.preventDefault(); event.currentTarget.form?.requestSubmit(); } }} placeholder="Scrie un mesaj..." rows={1} value={draft} /><button aria-label="Trimite mesajul" className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-[#30578F] text-white disabled:opacity-50" disabled={!draft.trim() || sending || !visibleThread || (visibleThread.ownerId === (user._id || user.id) && !selected.participantId)} type="submit"><span className="material-symbols-outlined">send</span></button></form>
          </>}
        </section>
      </div>}
    </main>
  </>;
}
