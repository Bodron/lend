import Head from "next/head";
import { Textarea } from "../components/ui/textarea";
import Link from "next/link";
import { useRouter } from "next/router";
import { useCallback, useEffect, useRef, useState } from "react";
import AppHeader from "../components/AppHeader";
import BrandLoader from "../components/BrandLoader";
import { useToastError } from "../lib/useToastError";
import UserAvatar from "../components/UserAvatar";
import ChatAvatar from "../components/ChatAvatar";
import OfferComposer from "../components/OfferComposer";
import { Bubble, BubbleContent } from "../components/ui/bubble";
import { Message, MessageAvatar, MessageContent, MessageFooter, MessageGroup } from "../components/ui/message";
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

function currentAvatarUrl(previousUrl, nextUrl) {
  if (!previousUrl || !nextUrl || previousUrl === nextUrl) return nextUrl;

  try {
    const previous = new URL(previousUrl);
    const next = new URL(nextUrl);
    if (previous.origin !== next.origin || previous.pathname !== next.pathname) return nextUrl;

    const signedDate = previous.searchParams.get("X-Amz-Date");
    const expiresIn = Number(previous.searchParams.get("X-Amz-Expires"));
    const match = signedDate?.match(/^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z$/);
    if (!match || !Number.isFinite(expiresIn) || expiresIn <= 0) return nextUrl;

    const [, year, month, day, hour, minute, second] = match;
    const signedAt = Date.UTC(Number(year), Number(month) - 1, Number(day), Number(hour), Number(minute), Number(second));
    if (Date.now() < signedAt + expiresIn * 1000 - 60_000) return previousUrl;
  } catch {
    // An invalid URL should never prevent messages from loading.
  }

  return nextUrl;
}

function time(value, locale) {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  return new Intl.DateTimeFormat(locale === "en" ? "en-GB" : "ro-RO", {
    day: "numeric", month: "short", hour: "2-digit", minute: "2-digit",
  }).format(date);
}

function preview(body, locale) {
  if (typeof body !== "string") return "";
  if (body.startsWith("@@roommate_proposal_accepted:")) return locale === "en" ? "Roommate proposal accepted" : "Propunere de coleg acceptată";
  if (body.startsWith("@@roommate_proposal:")) return locale === "en" ? "Roommate proposal" : "Propunere de coleg de apartament";
  return body;
}

function groupMessages(messages) {
  const groups = [];
  for (const message of messages) {
    const last = groups[groups.length - 1];
    if (last?.[0]?.senderId === message.senderId) last.push(message);
    else groups.push([message]);
  }
  return groups;
}

export default function MessagesPage() {
  const confirmAction = useConfirmAction();
  const router = useRouter();
  const en = router.locale === "en";
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [threads, setThreads] = useState([]);
  const [thread, setThread] = useState(null);
  const [draft, setDraft] = useState("");
  const [sending, setSending] = useState(false);
  const [offerForm, setOfferForm] = useState(false);
  const [, setError] = useToastError();
  const conversationRef = useRef(null);

  const loadThreads = useCallback(async () => {
    const result = await request("messageThreads");
    setThreads((previous) => {
      const previousByKey = new Map(previous.map((item) => [threadKey(item), item]));
      return (Array.isArray(result) ? result : []).map((item) => ({
        ...item,
        participantAvatarUrl: currentAvatarUrl(previousByKey.get(threadKey(item))?.participantAvatarUrl, item.participantAvatarUrl),
      }));
    });
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
        if (!cancelled) setThread((previous) => ({
          key: selectedKey,
          data: {
            ...result,
            participantAvatarUrl: currentAvatarUrl(previous?.key === selectedKey ? previous.data.participantAvatarUrl : null, result.participantAvatarUrl),
          },
        }));
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
    const panel = conversationRef.current;
    if (panel) panel.scrollTo({ top: panel.scrollHeight, behavior: "smooth" });
  }, [selectedKey, visibleThread?.messages?.length, visibleThread?.offers?.length]);

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
      title: en ? "Delete this conversation?" : "Ștergi conversația?",
      description: en ? "The conversation will be removed from your list." : "Conversația va fi eliminată din lista ta.",
      confirmLabel: en ? "Delete conversation" : "Șterge conversația",
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

  async function createOffer(offer) {
    if (!selected) throw new Error("Alege o conversație.");
    const from = offer.startDate.slice(0, 10);
    const to = offer.rentalMode === "hour"
      ? new Date(Date.parse(`${from}T00:00:00Z`) + 86400000).toISOString().slice(0, 10)
      : offer.endDate.slice(0, 10);
    const availability = await request(`offerAvailability?${new URLSearchParams({ productId: selected.productId, from, to })}`);

    if (offer.rentalMode === "hour") {
      const start = Date.parse(offer.startDate);
      const end = Date.parse(offer.endDate) + 3600000;
      const blocked = availability.manualBlocks?.some((block) => Date.parse(`${block.startDate}T00:00:00Z`) < end && Date.parse(`${block.endDate}T00:00:00Z`) > start);
      const events = [{ at: start, change: 1 }, { at: end, change: -1 }];
      for (const reservation of availability.reservations || []) {
        const occupiedFrom = Date.parse(reservation.occupiedFrom);
        const occupiedUntil = Date.parse(reservation.occupiedUntil);
        if (occupiedFrom < end && occupiedUntil > start) {
          events.push({ at: Math.max(start, occupiedFrom), change: 1 });
          events.push({ at: Math.min(end, occupiedUntil), change: -1 });
        }
      }
      events.sort((a, b) => a.at - b.at || a.change - b.change);
      let occupied = 0;
      const full = events.some((event) => { occupied += event.change; return occupied > offer.stockQuantity; });
      if (blocked || full) throw new Error("Perioada selectată este deja ocupată. Alege alte ore.");
    } else if (availability.unavailableDates?.some((day) => day >= from && day < to)) {
      throw new Error("Perioada selectată este deja ocupată. Alege alte date.");
    }

    await request("offerCreate", { method: "POST", body: JSON.stringify({
      productId: selected.productId,
      amount: offer.amount,
      startDate: offer.startDate,
      endDate: offer.endDate,
      rentalMode: offer.rentalMode,
    }) });
    setOfferForm(false);
    setThread({ key: selectedKey, data: await request(threadAction(selected)) });
  }

  return <>
    <Head><title>{`${en ? "Messages" : "Mesaje"} | PINLEND`}</title><meta name="description" content={en ? "Your PINLEND conversations." : "Conversațiile tale PINLEND."} /></Head>
    <AppHeader />
    <main className="mx-auto max-w-7xl px-5 pb-16 pt-10 md:px-8">
      <p className="font-mono text-xs uppercase tracking-[0.25em] text-[#30578F]">PINLEND / {en ? "Conversations" : "Conversații"}</p>
      <h1 className="mt-3 font-display text-4xl font-extrabold md:text-6xl">{en ? "Messages" : "Mesaje"}</h1>

      {loading ? <BrandLoader className="mt-10 py-16" label={en ? "Loading messages..." : "Se încarcă mesajele..."} /> : user && <div className="mt-9 grid h-[calc(100dvh-220px)] min-h-[420px] overflow-hidden rounded-[20px] border border-black/10 bg-white shadow-sm md:h-[680px] md:grid-cols-[310px_minmax(0,1fr)]">
        <aside className={`${selected ? "hidden md:flex" : "flex"} min-h-0 flex-col border-b border-black/10 md:border-b-0 md:border-r`}>
          <div className="flex items-center justify-between border-b border-black/10 px-5 py-4"><h2 className="font-extrabold">{en ? "Conversations" : "Conversații"}</h2><button aria-label={en ? "Refresh conversations" : "Actualizează conversațiile"} className="text-[#30578F]" onClick={() => loadThreads().catch((cause) => setError(cause.message))} type="button"><span className="material-symbols-outlined">refresh</span></button></div>
          {threads.length === 0 ? <p className="p-5 text-sm text-[#626977]">{en ? "You have no messages yet. Open a listing and write to its owner." : "Nu ai încă mesaje. Deschide un anunț și scrie proprietarului."}</p> : <div className="min-h-0 flex-1 overflow-y-auto">{threads.map((item) => <Link className={`block border-b border-black/5 p-4 transition-colors hover:bg-[#F2F6FC] ${threadKey(item) === selectedKey ? "bg-[#E7F0FD]" : ""}`} href={threadUrl(item)} key={threadKey(item)}>
            <div className="flex items-start gap-3">
              <ChatAvatar className="size-11" key={item.participantId} name={item.participantName || "P"} src={item.participantAvatarUrl} />
              <div className="min-w-0 flex-1"><div className="flex items-center justify-between gap-2"><p className="truncate font-extrabold">{item.participantName || (en ? "User" : "Utilizator")}</p>{item.unreadCount > 0 && <span className="rounded-full bg-[#30578F] px-2 py-0.5 text-xs font-bold text-white">{item.unreadCount}</span>}</div><p className="mt-1 truncate text-xs text-[#626977]">{item.productTitle || (en ? "Listing" : "Anunț")}</p><p className="mt-2 truncate text-sm text-[#434750]">{preview(item.latestMessage?.body, router.locale)}</p></div>
            </div>
          </Link>)}</div>}
        </aside>
        <section className={`${selected ? "flex" : "hidden md:flex"} min-h-0 min-w-0 flex-col overflow-hidden`} aria-label={en ? "Conversation" : "Conversație"}>
          {!selected ? <div className="m-auto px-6 text-center text-[#626977]"><span className="material-symbols-outlined text-5xl text-[#30578F]">forum</span><p className="mt-3 font-bold">{en ? "Choose a conversation or message someone from a listing." : "Alege o conversație sau scrie din pagina unui anunț."}</p></div> : <>
            <div className="flex items-center justify-between gap-3 border-b border-black/10 px-4 py-4 md:px-6">
              <div className="flex min-w-0 items-center gap-3"><Link aria-label={en ? "Back to conversations" : "Înapoi la conversații"} className="md:hidden" href="/mesaje"><span className="material-symbols-outlined">arrow_back</span></Link><div className="min-w-0"><p className="truncate font-extrabold">{visibleThread?.participantName || (en ? "Conversation" : "Conversație")}</p><p className="truncate text-xs text-[#626977]">{visibleThread?.productTitle || (en ? "PINLEND listing" : "Anunț PINLEND")}</p></div></div>
              <div className="flex shrink-0 items-center gap-2">
                {visibleThread?.productSlug && !selected.roommateInterestId && visibleThread.ownerId !== (user._id || user.id) && (
                  <button
                    className="inline-flex h-10 items-center justify-center whitespace-nowrap rounded-lg bg-black px-4 text-sm font-bold text-white transition-colors hover:bg-[#242424] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-black"
                    onClick={() => setOfferForm(!offerForm)}
                    type="button"
                  >
                    {router.locale === "en" ? "Make an offer" : "Propune preț"}
                  </button>
                )}
                <button
                  aria-label={en ? "Delete conversation" : "Șterge conversația"}
                  className="inline-flex h-10 w-10 items-center justify-center rounded-lg text-[#626977] hover:text-red-700"
                  onClick={removeThread}
                  type="button"
                >
                  <span className="material-symbols-outlined">delete</span>
                </button>
              </div>
            </div>
            {offerForm && visibleThread?.productSlug && <OfferComposer key={selectedKey} onClose={() => setOfferForm(false)} onSubmit={createOffer} productSlug={visibleThread.productSlug} />}
            <div
              className="min-h-0 flex-1 space-y-5 overflow-y-auto bg-white px-4 py-6 text-[#1B1B1B] md:px-6"
              ref={conversationRef}
              style={{ "--primary": "#2146C7", "--secondary": "#F3F4F6", "--secondary-foreground": "#1B1B1B" }}
            >
              {!visibleThread ? (
                <BrandLoader className="py-12" label={en ? "Loading conversation..." : "Se încarcă conversația..."} />
              ) : visibleThread.ownerId === (user._id || user.id) && !selected.participantId ? (
                <p className="py-12 text-center text-sm text-[#626977]">{en ? "Choose a conversation from the list to reply to the right person." : "Alege conversația din listă pentru a răspunde persoanei potrivite."}</p>
              ) : visibleThread.messages?.length ? (
                groupMessages(visibleThread.messages).map((group, groupIndex) => {
                  const mine = group[0].senderId === (user._id || user.id);
                  const avatarUser = mine
                    ? user
                    : { fullName: visibleThread.participantName || (en ? "User" : "Utilizator"), avatarUrl: visibleThread.participantAvatarUrl };
                  return (
                    <MessageGroup className="gap-1" key={group[0]._id || group[0].id || groupIndex}>
                      {group.map((message, index) => {
                        const isLast = index === group.length - 1;
                        return (
                          <Message align={mine ? "end" : "start"} key={message._id || message.id || index}>
                            <MessageAvatar className="bg-transparent">
                              {isLast && (mine
                                ? <UserAvatar className="size-8 ring-2 ring-white" user={avatarUser} />
                                : <ChatAvatar className="size-8 ring-2 ring-white" key={visibleThread.participantId} name={avatarUser.fullName} src={avatarUser.avatarUrl} />)}
                            </MessageAvatar>
                            <MessageContent className="gap-1">
                              <Bubble variant={mine ? "default" : "secondary"}>
                                <BubbleContent className="rounded-[20px] px-4 py-2.5 text-sm font-medium leading-6">
                                  <p className="whitespace-pre-wrap break-words">{preview(message.body, router.locale)}</p>
                                </BubbleContent>
                              </Bubble>
                              {isLast && <MessageFooter className="text-[11px] text-[#626977]">{time(message.createdAt, router.locale)}</MessageFooter>}
                            </MessageContent>
                          </Message>
                        );
                      })}
                    </MessageGroup>
                  );
                })
              ) : (
                <p className="py-12 text-center text-sm text-[#626977]">{en ? "No messages yet. Send the first one." : "Niciun mesaj încă. Scrie primul mesaj."}</p>
              )}
              {visibleThread?.offers?.map((offer) => (
                <article className="mx-auto max-w-xl rounded-2xl border border-[#DCE2EB] bg-white p-4 text-[#1B1B1B] shadow-sm" key={offer._id}>
                  <p className="font-bold">{en ? "Offer" : "Ofertă"}: {offer.amount} RON</p>
                  <p className="mt-1 text-xs text-[#626977]">{String(offer.startDate).slice(0, 10)} – {String(offer.endDate).slice(0, 10)} · {offer.rentalMode} · {offer.status}</p>
                  {offer.recipientId === (user._id || user.id) && offer.status === "pending" && (
                    <div className="mt-3 flex flex-wrap gap-2">
                      <button className="account-button" onClick={() => updateOffer("offerAccept", offer._id)} type="button">{en ? "Accept" : "Acceptă"}</button>
                      <button className="account-button-light" onClick={() => updateOffer("offerReject", offer._id)} type="button">{en ? "Decline" : "Respinge"}</button>
                    </div>
                  )}
                  {offer.senderId === (user._id || user.id) && offer.status === "accepted" && visibleThread.productSlug && (
                    <Link className="account-button mt-3 inline-block" href={`/inchiriaza/${encodeURIComponent(visibleThread.productSlug)}?offerId=${encodeURIComponent(offer._id)}`}>{en ? "Continue to payment" : "Continuă către plată"}</Link>
                  )}
                </article>
              ))}
            </div>
            <form className="flex shrink-0 items-end gap-3 border-t border-black/10 bg-white p-4 md:p-5" onSubmit={send}><label className="sr-only" htmlFor="message-draft">{en ? "Message" : "Mesaj"}</label><Textarea className="min-h-12 max-h-36 flex-1 resize-y rounded-2xl border border-[#D1D5DB] bg-[#F9FAFB] px-4 py-3 text-sm text-[#1B1B1B] outline-none placeholder:text-[#626977] focus:border-[#30578F]" id="message-draft" maxLength={2000} onChange={(event) => setDraft(event.target.value)} onKeyDown={(event) => { if (event.key === "Enter" && !event.shiftKey) { event.preventDefault(); event.currentTarget.form?.requestSubmit(); } }} placeholder={en ? "Write a message..." : "Scrie un mesaj..."} rows={1} value={draft} /><button aria-label={en ? "Send message" : "Trimite mesajul"} className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-[#2146C7] text-white disabled:opacity-50" disabled={!draft.trim() || sending || !visibleThread || (visibleThread.ownerId === (user._id || user.id) && !selected.participantId)} type="submit"><span className="material-symbols-outlined">send</span></button></form>
          </>}
        </section>
      </div>}
    </main>
  </>;
}
