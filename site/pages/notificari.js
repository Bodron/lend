import Head from "next/head";
import Link from "next/link";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import AppHeader from "../components/AppHeader";
import { Checkbox } from "../components/ui/checkbox";
import { accountRequest, requireLogin } from "../lib/accountRequest";
import { useToastError } from "../lib/useToastError";

const readKey = "pinlend_web_read_notifications";
const idOf = (item) => String(item?._id || item?.id || "");

function createItems(user, threads, viewings, owned, renting, en) {
  const id = user.id || user._id;
  return [
    ...threads.filter((item) => item.unreadCount > 0).map((item) => ({
      id: `message:${item.productId}:${item.roommateInterestId || ""}:${item.latestMessage?._id || ""}`,
      title: en ? `${item.unreadCount} unread message(s)` : `${item.unreadCount} mesaj(e) necitite`, body: item.productTitle,
      href: `/mesaje?productId=${encodeURIComponent(item.productId)}${item.roommateInterestId ? `&roommateInterestId=${encodeURIComponent(item.roommateInterestId)}` : ""}`,
      date: item.latestMessage?.createdAt,
    })),
    ...viewings.filter((item) => (item.ownerId === id && item.status === "requested") || (item.visitorId === id && ["counter_proposed", "awaiting_payment"].includes(item.status))).map((item) => ({
      id: `viewing:${idOf(item)}:${item.status}`, title: item.status === "requested" ? (en ? "New viewing request" : "Cerere nouă de vizionare") : item.status === "awaiting_payment" ? (en ? "Viewing accepted, payment pending" : "Vizionare acceptată, așteaptă plata") : (en ? "The owner suggested another time" : "Proprietarul a propus altă oră"),
      body: item.productTitle, href: "/vizionari", date: item.updatedAt || item.createdAt,
    })),
    ...owned.filter((item) => item.status === "pending" && ["authorized", "captured"].includes(item.paymentStatus)).map((item) => ({
      id: `owned:${idOf(item)}:${item.status}`, title: en ? "New rental request" : "Cerere nouă de închiriere", body: item.productSnapshot?.title || (en ? "Listing" : "Anunț"), href: "/account?section=rentals", date: item.updatedAt || item.createdAt,
    })),
    ...renting.filter((item) => item.status === "confirmed").map((item) => ({
      id: `renting:${idOf(item)}:${item.status}`, title: en ? "Rental confirmed" : "Închirierea a fost confirmată", body: item.productSnapshot?.title || (en ? "Listing" : "Anunț"), href: "/account?section=rentals", date: item.updatedAt || item.createdAt,
    })),
  ].sort((a, b) => new Date(b.date || 0) - new Date(a.date || 0));
}

export default function NotificationsPage() {
  const en = useRouter().locale === "en";
  const [items, setItems] = useState([]);
  const [read, setRead] = useState([]);
  const [unreadOnly, setUnreadOnly] = useState(false);
  const [, setError] = useToastError();
  useEffect(() => {
    let cancelled = false;
    try { const saved = JSON.parse(window.localStorage.getItem(readKey) || "[]"); Promise.resolve().then(() => { if (!cancelled) setRead(Array.isArray(saved) ? saved : []); }); } catch { /* Empty storage. */ }
    async function load() {
      try {
        const [user, threads, viewings, owned, renting] = await Promise.all([
          accountRequest("me"), accountRequest("messageThreads"), accountRequest("viewingList"), accountRequest("orders"), accountRequest("renterOrders"),
        ]);
        if (!cancelled) setItems(createItems(user, threads, viewings, owned, renting, en));
      } catch (cause) { if (!cancelled && !requireLogin(cause, "/notificari")) setError(cause.message); }
    }
    load();
    const timer = window.setInterval(() => { if (document.visibilityState === "visible") load(); }, 30000);
    return () => { cancelled = true; window.clearInterval(timer); };
  }, [setError, en]);
  function mark(id) {
    const next = [...new Set([...read, id])]; setRead(next); window.localStorage.setItem(readKey, JSON.stringify(next));
  }
  const visible = unreadOnly ? items.filter((item) => !read.includes(item.id)) : items;
  return <>
    <Head><title>{`${en ? "Notifications" : "Notificări"} | PINLEND`}</title></Head>
    <AppHeader />
    <main className="mx-auto max-w-4xl px-5 py-12 md:px-8"><p className="font-mono text-xs uppercase tracking-widest text-[#30578F]">{en ? "Activity" : "Activitate"}</p><h1 className="mt-3 font-display text-4xl font-extrabold">{en ? "Notifications" : "Notificări"}</h1><p className="mt-3 text-[#626977]">{en ? "Messages, viewing requests, and rentals waiting for your response." : "Mesaje, cereri de vizionare și închirieri care așteaptă un răspuns."}</p>
      <div className="mt-7 flex flex-wrap items-center gap-4"><label className="flex items-center gap-2 text-sm font-bold"><Checkbox checked={unreadOnly} onCheckedChange={(checked) => setUnreadOnly(checked === true)} />{en ? "Unread only" : "Doar necitite"}</label><button className="text-sm font-bold text-[#30578F]" onClick={() => { const next = items.map((item) => item.id); setRead(next); window.localStorage.setItem(readKey, JSON.stringify(next)); }} type="button">{en ? "Mark all as read" : "Marchează toate citite"}</button></div>
      <div className="mt-6 space-y-3">{visible.map((item) => <Link className={`block rounded-2xl border p-5 transition-colors hover:border-[#30578F] ${read.includes(item.id) ? "border-black/10 bg-white" : "border-[#30578F]/30 bg-[#E7F0FD]"}`} href={item.href} key={item.id} onClick={() => mark(item.id)}><div className="flex justify-between gap-4"><div><h2 className="font-extrabold">{item.title}</h2><p className="mt-1 text-sm text-[#626977]">{item.body}</p></div><span className="material-symbols-outlined text-[#30578F]">arrow_forward</span></div></Link>)}{visible.length === 0 && <p className="account-card text-[#626977]">{en ? "No notifications in this section." : "Nu ai notificări în această secțiune."}</p>}</div>
    </main>
  </>;
}
