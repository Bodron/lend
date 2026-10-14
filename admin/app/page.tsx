"use client";

import { FormEvent, useCallback, useEffect, useState } from "react";

type Section = "overview" | "orders" | "viewings" | "sellers" | "users" | "products" | "deletions";
type Row = Record<string, unknown> & { _id: string };
type ListResponse = { items: Row[]; total: number; page: number; pageSize: number };
type Overview = {
  users: number; products: number; closedProducts: number; pendingDeletions: number; orders: number; viewings: number;
  rentalMoney: { capturedRon: number; platformFeeRon: number; transferredRon: number };
  viewingMoney: { capturedRon: number; transferredRon: number };
};

const sections: { key: Section; label: string; icon: string }[] = [
  { key: "overview", label: "Prezentare", icon: "â—«" },
  { key: "orders", label: "ÃŽnchirieri", icon: "â–£" },
  { key: "viewings", label: "Vizionări", icon: "◉" },
  { key: "sellers", label: "Vânzări / proprietari", icon: "▥" },
  { key: "users", label: "Utilizatori", icon: "â™™" },
  { key: "products", label: "Anunțuri", icon: "▤" },
  { key: "deletions", label: "Ștergeri cont", icon: "⌫" },
];
const titles: Record<Section, string> = {
  overview: "Privire de ansamblu", orders: "Închirieri și plăți", viewings: "Vizionări plătite",
  sellers: "Vânzări pe proprietar", users: "Utilizatori", products: "Moderare anunțuri", deletions: "Cereri de ștergere",
};
const currency = (value: unknown) => new Intl.NumberFormat("ro-RO", { style: "currency", currency: "RON" }).format(Number(value) || 0);
const date = (value: unknown) => value ? new Intl.DateTimeFormat("ro-RO", { dateStyle: "medium", timeStyle: "short" }).format(new Date(String(value))) : "—";
const str = (value: unknown) => typeof value === "string" && value ? value : "—";
const id = (value: unknown) => String(value ?? "");
async function json(url: string, init?: RequestInit) {
  const response = await fetch(url, { ...init, cache: "no-store" });
  const body = await response.json();
  if (!response.ok) throw new Error(Array.isArray(body.message) ? body.message.join(", ") : body.message || "Cererea a eșuat.");
  return body;
}

export default function Home() {
  const [user, setUser] = useState<{ fullName: string; email: string } | null>(null);
  const [checking, setChecking] = useState(true);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [section, setSection] = useState<Section>("overview");
  const [overview, setOverview] = useState<Overview | null>(null);
  const [list, setList] = useState<ListResponse | null>(null);
  const [sellers, setSellers] = useState<ListResponse | null>(null);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const [query, setQuery] = useState("");
  const [loading, setLoading] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [moderating, setModerating] = useState<Row | null>(null);
  const [reason, setReason] = useState("");

  useEffect(() => {
    json("/api/admin/me").then(setUser).catch(() => setUser(null)).finally(() => setChecking(false));
  }, []);

  const load = useCallback(async () => {
    if (!user) return;
    setLoading(true); setError("");
    try {
      if (section === "overview") setOverview(await json("/api/admin/overview"));
      else if (section === "sellers") setSellers(await json(`/api/admin/sellers?page=${page}`));
      else setList(await json(`/api/admin/${section}?page=${page}&q=${encodeURIComponent(query)}`));
    } catch (e) { setError((e as Error).message); }
    finally { setLoading(false); }
  }, [user, section, page, query]);

  useEffect(() => { void load(); }, [load]);

  async function signIn(event: FormEvent) {
    event.preventDefault(); setBusy(true); setError("");
    try {
      const result = await json("/api/session", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ email, password }) });
      setUser(result.user); setPassword("");
    } catch (e) { setError((e as Error).message); }
    finally { setBusy(false); }
  }

  async function signOut() {
    await json("/api/session", { method: "DELETE" });
    setUser(null); setOverview(null); setList(null); setSection("overview");
  }

  async function moderate() {
    if (!moderating) return;
    const closed = moderating.isClosedByAdmin !== true;
    if (closed && !reason.trim()) { setError("Adaugă motivul închiderii."); return; }
    setBusy(true); setError("");
    try {
      await json(`/api/admin/products/${moderating._id}/moderation`, {
        method: "PATCH", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ closed, reason: reason.trim() }),
      });
      setModerating(null); setReason(""); await load();
    } catch (e) { setError((e as Error).message); }
    finally { setBusy(false); }
  }

  if (checking) return <div className="center">Se verifică sesiunea…</div>;
  if (!user) return <main className="login-wrap"><div className="login-card">
    <div className="brand-mark">P</div><div className="eyebrow">PINLEND · ADMIN</div>
    <h1>Bine ai revenit.</h1><p>Conectează-te cu un cont care are rolul super_admin.</p>
    <form onSubmit={signIn}><label>Email<input type="email" value={email} onChange={e => setEmail(e.target.value)} required autoComplete="username" /></label>
      <label>Parolă<input type="password" value={password} onChange={e => setPassword(e.target.value)} required autoComplete="current-password" /></label>
      {error && <div className="error">{error}</div>}<button className="primary" disabled={busy}>{busy ? "Se conectează…" : "Intră în panou"}</button></form>
  </div></main>;

  const stats = overview ? [
    ["Plăți închirieri capturate", currency(overview.rentalMoney.capturedRon), "Include garanții; exclude plăți în așteptare"],
    ["Taxe platformă", currency(overview.rentalMoney.platformFeeRon), "Din închirieri capturate"],
    ["Transferuri proprietari", currency(overview.rentalMoney.transferredRon + overview.viewingMoney.transferredRon), "Închirieri și vizionări transferate"],
    ["Vizionări încasate", currency(overview.viewingMoney.capturedRon), "Plăți marcate ca încasate"],
  ] : [];

  return <div className="shell"><aside className="sidebar">
    <div className="brand"><div className="brand-mark">P</div><div><strong>PINLEND</strong><small>ADMIN CONSOLE</small></div></div>
    <div className="nav-caption">MENIU PRINCIPAL</div>
    <nav>{sections.map(item => <button key={item.key} className={section === item.key ? "nav-item active" : "nav-item"} onClick={() => { setSection(item.key); setPage(1); setList(null); setSellers(null); setSearch(""); setQuery(""); setError(""); }}><span className="nav-icon">{item.icon}</span>{item.label}{item.key === "deletions" && overview?.pendingDeletions ? <b className="nav-badge">{overview.pendingDeletions}</b> : null}</button>)}</nav>
    <div className="sidebar-foot"><span className="avatar">{user.fullName.slice(0, 1).toUpperCase()}</span><div><strong>{user.fullName}</strong><small>{user.email}</small></div><button onClick={signOut} title="Ieși din cont">⇥</button></div>
  </aside><main className="main"><header className="topbar"><div className="breadcrumb">Administrare <span>/</span> {titles[section]}</div><div className="live"><i /> Date din backend</div></header>
    <div className="content"><div className="heading"><div><div className="eyebrow">PANOU DE CONTROL</div><h1>{titles[section]}</h1><p>{section === "overview" ? "Activitatea platformei într-un singur loc." : section === "deletions" ? "Istoricul cererilor de ștergere trimise de utilizatori." : "Datele sunt citite direct din API-ul PINLEND."}</p></div><button className="refresh" onClick={load} disabled={loading}>↻ &nbsp; Actualizează</button></div>
    {error && <div className="error banner">{error}</div>}
    {section === "sellers" ? <div className="panel"><div className="panel-head"><div><h2>Proprietari cu încasări</h2><p>Top 100 după valoarea închirierilor capturate</p></div></div><div className="table-scroll"><table><thead><tr><th>Proprietar</th><th>Vânzări</th><th>Valoare</th><th>Transferat</th></tr></thead><tbody>{sellers?.items.map(row => <tr key={String((row._id as unknown as Record<string, unknown>)?.ownerId)}><td><strong>{str((row._id as unknown as Record<string, unknown>)?.ownerName)}</strong></td><td>{Number(row.sales)}</td><td>{currency(row.grossRon)}</td><td>{currency(row.transferredRon)}</td></tr>)}</tbody></table></div><div className="pager"><span>{sellers ? `Pagina ${sellers.page} din ${Math.max(1, Math.ceil(sellers.total / sellers.pageSize))}` : ""}</span><div><button disabled={page <= 1 || loading} onClick={() => setPage(page - 1)}>← Înapoi</button><button disabled={!sellers || page * sellers.pageSize >= sellers.total || loading} onClick={() => setPage(page + 1)}>Înainte →</button></div></div></div> : section === "overview" ? <>{overview && <><div className="stats-grid">{stats.map(([label, value, note]) => <div className="stat-card" key={label}><span>{label}</span><strong>{value}</strong><small>{note}</small></div>)}</div><div className="panel"><div className="panel-head"><div><h2>Activitatea platformei</h2><p>Volume totale în baza de date</p></div></div><div className="activity-grid">{[["Utilizatori", overview.users], ["AnunÈ›uri", overview.products], ["ÃŽnchirieri", overview.orders], ["Vizionări", overview.viewings], ["AnunÈ›uri închise", overview.closedProducts], ["Cereri È™tergere active", overview.pendingDeletions]].map(([label, value]) => <div key={label}><strong>{value}</strong><span>{label}</span></div>)}</div></div><p className="footnote">Sumele sunt calculate din statusurile locale. Rambursările È™i disputele nu sunt încă scăzute automat din totalurile istorice; verifică Stripe pentru reconcilierea contabilă.</p></>}{loading && !overview && <div className="empty">Se încarcă datele…</div>}</> : <div className="panel"><div className="panel-head"><div><h2>{titles[section]}</h2><p>{list ? `${list.total} rezultate` : "Se încarcă…"}</p></div>{(section === "users" || section === "products") && <form className="search" onSubmit={e => { e.preventDefault(); setPage(1); setQuery(search); }}><input placeholder="Caută nume, email, anunț…" value={search} onChange={e => setSearch(e.target.value)} /><button type="submit">Caută</button></form>}</div>
      <div className="table-scroll"><table><thead><tr>{section === "users" || section === "deletions" ? <><th>Utilizator</th><th>Rol</th><th>{section === "deletions" ? "Cerere" : "Înregistrat"}</th><th>Status</th></> : section === "products" ? <><th>Anunț</th><th>Proprietar</th><th>Preț / zi</th><th>Status</th><th>Acțiune</th></> : section === "orders" ? <><th>Închiriere</th><th>Plată</th><th>Total</th><th>Transfer</th><th>Data</th></> : <><th>Vizionare</th><th>Vizitator</th><th>Încasat</th><th>Transfer</th><th>Data</th></>}</tr></thead><tbody>
      {list?.items.map(row => <tr key={row._id}>{section === "users" || section === "deletions" ? <><td><strong>{str(row.fullName)}</strong><small>{str(row.email)} · {str(row.phone)}</small></td><td><span className="pill">{str(row.role || "user")}</span></td><td>{date(section === "deletions" ? row.deletionRequestedAt : row.createdAt)}</td><td><span className="pill">{str(row.deletionRequestStatus || "activ")}</span></td></> : section === "products" ? <><td><strong>{str(row.title)}</strong><small>{str(row.city)} · {row._id}</small></td><td>{str(row.ownerName)}</td><td>{currency(row.pricePerDay)}</td><td><span className={`pill ${row.isClosedByAdmin ? "danger" : "success"}`}>{row.isClosedByAdmin ? "Închis" : "Activ"}</span>{row.isClosedByAdmin === true && <small>{str(row.adminCloseReason)}</small>}</td><td><button className="action" onClick={() => { setModerating(row); setReason(""); }}>{row.isClosedByAdmin ? "Redeschide" : "Închide"}</button></td></> : section === "orders" ? <><td><strong>{str((row.productSnapshot as Record<string, unknown> | undefined)?.title)}</strong><small>#{id(row._id).slice(-8)} · {str(row.status)}</small></td><td><span className="pill">{str(row.paymentStatus)}</span></td><td>{currency(row.total)}</td><td><strong>{currency(row.payoutStatus === "paid_out" ? row.sellerNetAmount : 0)}</strong><small>{str(row.payoutStatus)}</small></td><td>{date(row.createdAt)}</td></> : <><td><strong>{str(row.productTitle)}</strong><small>#{id(row._id).slice(-8)} · {str(row.status)}</small></td><td>{str(row.visitorName)}</td><td>{currency(row.paidAt ? Number(row.priceRon || 0) + Number(row.serviceFeeRon || 0) : 0)}</td><td>{row.stripeTransferId ? currency(row.priceRon) : "—"}</td><td>{date(row.startsAt)}</td></>}</tr>)}
      {!loading && list?.items.length === 0 && <tr><td colSpan={5} className="empty-cell">Nu există rezultate pentru această selecție.</td></tr>}
      </tbody></table></div><div className="pager"><span>{list ? `Pagina ${list.page} din ${Math.max(1, Math.ceil(list.total / list.pageSize))}` : ""}</span><div><button disabled={page <= 1 || loading} onClick={() => setPage(page - 1)}>← Înapoi</button><button disabled={!list || page * list.pageSize >= list.total || loading} onClick={() => setPage(page + 1)}>Înainte →</button></div></div></div>}
    </div></main>{moderating && <div className="modal-backdrop" onMouseDown={() => setModerating(null)}><div className="modal" onMouseDown={e => e.stopPropagation()}><div className="eyebrow">MODERARE ANUNȚ</div><h2>{moderating.isClosedByAdmin ? "Redeschide anunțul?" : "Închide anunțul?"}</h2><p>{str(moderating.title)}</p>{!moderating.isClosedByAdmin && <label>Motivul închiderii<textarea value={reason} onChange={e => setReason(e.target.value)} maxLength={500} placeholder="Descrie motivul pentru istoricul moderării" /></label>}<div className="modal-actions"><button onClick={() => setModerating(null)}>Renunță</button><button className="primary" disabled={busy || (moderating.isClosedByAdmin !== true && !reason.trim())} onClick={moderate}>{busy ? "Se salvează…" : "Confirmă"}</button></div></div></div>}</div>;
}
