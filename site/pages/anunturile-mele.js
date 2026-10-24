/* eslint-disable @next/next/no-img-element */
import Head from "next/head";
import { useToastNotice } from "../lib/useToastNotice";
import FormSelect from "../components/FormSelect";
import { Input } from "../components/ui/input";
import { Checkbox } from "../components/ui/checkbox";
import { RentalDateField, RentalTimeField } from "../components/RentalPeriodFields";
import { Textarea } from "../components/ui/textarea";
import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import AppHeader from "../components/AppHeader";
import PinlendMap from "../components/PinlendMap";
import { accountRequest, requireLogin } from "../lib/accountRequest";
import { getBackendApiUrl } from "../lib/backendApi";
import { useToastError } from "../lib/useToastError";
import { useConfirmAction } from "../components/ConfirmActionProvider";

const initialForm = {
  title: "", categorySlug: "", category: "", description: "", pricePerDay: "", pricePerMonth: "",
  deposit: "0", stockQuantity: "1", city: "", address: "", latitude: "", longitude: "",
  availabilityScope: "local", pickupTime: "10:00", returnTime: "18:00",
  rentalModes: ["day"], viewingsEnabled: false, viewingPriceRon: "0",
};
const idOf = (item) => String(item?._id || item?.id || "");
const dateOnly = (date) => date.toISOString().slice(0, 10);

export async function getServerSideProps() {
  try {
    const response = await fetch(`${getBackendApiUrl()}/categories`, { signal: AbortSignal.timeout(8000) });
    return { props: { categories: response.ok ? await response.json() : [] } };
  } catch { return { props: { categories: [] } }; }
}

export default function MyListings({ categories }) {
  const confirmAction = useConfirmAction();
  const [user, setUser] = useState(null);
  const [listings, setListings] = useState([]);
  const [selected, setSelected] = useState(null);
  const [form, setForm] = useState(initialForm);
  const [media, setMedia] = useState([]);
  const [availability, setAvailability] = useState(null);
  const [block, setBlock] = useState({ startDate: "", endDate: "", reason: "" });
  const [busy, setBusy] = useState(false);
  const [showLocationMap, setShowLocationMap] = useState(false);
  const pickerPoints = useMemo(() => {
    if (form.latitude === "" || form.longitude === "") return [];
    const latitude = Number(form.latitude);
    const longitude = Number(form.longitude);
    return Number.isFinite(latitude) && Number.isFinite(longitude) && Math.abs(latitude) <= 90 && Math.abs(longitude) <= 180
      ? [{ id: "listing-location", latitude, longitude, title: "Locația anunțului" }]
      : [];
  }, [form.latitude, form.longitude]);
  const [, setError] = useToastError();
  const setNotice = useToastNotice();

  async function refresh() {
    const [profile, products] = await Promise.all([accountRequest("me"), accountRequest("listings")]);
    setUser(profile);
    setListings(Array.isArray(products) ? products : []);
  }

  function select(item) {
    setSelected(item);
    setMedia(item?.images?.map(({ key, url, alt, contentType, type, thumbnailKey }) => ({ key, url, alt, contentType, type, ...(thumbnailKey ? { thumbnailKey } : {}) })) || []);
    setForm(item ? {
      ...initialForm, ...item,
      pricePerDay: String(item.pricePerDay ?? ""), pricePerMonth: String(item.pricePerMonth ?? ""),
      deposit: String(item.deposit ?? 0), stockQuantity: String(item.stockQuantity ?? 1),
      viewingPriceRon: String(item.viewingPriceRon ?? 0),
      latitude: item.latitude == null ? "" : String(item.latitude),
      longitude: item.longitude == null ? "" : String(item.longitude),
      rentalModes: item.rentalModes?.length ? item.rentalModes : ["day"],
    } : initialForm);
    setAvailability(null);
    setError("");
    setNotice("");
    if (item) {
      loadAvailability(idOf(item));
      requestAnimationFrame(() => document.getElementById("listing-editor")?.scrollIntoView({ behavior: "smooth", block: "start" }));
    }
  }

  async function loadAvailability(productId) {
    const from = dateOnly(new Date());
    const to = dateOnly(new Date(Date.now() + 90 * 86400000));
    try { setAvailability(await accountRequest(`rentalAvailability?${new URLSearchParams({ productId, from, to })}`)); }
    catch (cause) { setError(cause.message); }
  }

  useEffect(() => {
    let active = true;
    Promise.all([accountRequest("me"), accountRequest("listings")]).then(([profile, products]) => {
      if (!active) return;
      setUser(profile);
      setListings(Array.isArray(products) ? products : []);
      const id = new URLSearchParams(window.location.search).get("id");
      const item = products.find((product) => idOf(product) === id);
      if (item) select(item);
    }).catch((cause) => { if (active && !requireLogin(cause, "/anunturile-mele")) setError(cause.message); });
    return () => { active = false; };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  async function uploadMedia(event) {
    const files = [...event.target.files].slice(0, 8 - media.length);
    if (!files.length) return;
    setBusy(true); setError("");
    try {
      const added = [];
      for (const file of files) {
        const video = ["video/mp4", "video/quicktime"].includes(file.type);
        if (!["image/jpeg", "image/png", "image/webp", "video/mp4", "video/quicktime"].includes(file.type) || file.size > (video ? 200_000_000 : 10_000_000)) throw new Error("Folosește JPG, PNG, WebP (max. 10 MB) sau video MP4/MOV (max. 200 MB).");
        const upload = await accountRequest("uploadUrl", { method: "POST", body: JSON.stringify({ fileName: file.name, contentType: file.type, size: file.size }) });
        const response = await fetch(upload.uploadUrl, { method: "PUT", headers: upload.headers || { "Content-Type": file.type }, body: file });
        if (!response.ok) throw new Error("Încărcarea imaginii a eșuat.");
        added.push({ key: upload.key, url: upload.readableUrl, alt: form.title || file.name, contentType: file.type, type: video ? "video" : "image" });
      }
      setMedia((previous) => [...previous, ...added]);
    } catch (cause) { setError(cause.message); }
    finally { setBusy(false); event.target.value = ""; }
  }

  async function save(event) {
    event.preventDefault();
    setBusy(true); setError(""); setNotice("");
    try {
      if (!form.categorySlug) throw new Error("Alege categoria anunțului.");
      if (form.rentalModes.includes("month") && (!form.pricePerMonth || Number(form.pricePerMonth) < 1)) throw new Error("Adaugă prețul lunar pentru închirierea pe lună.");
      const category = categories.find((item) => item.slug === form.categorySlug);
      const payload = {
        title: form.title.trim(), categorySlug: form.categorySlug, category: category?.name || form.category || form.categorySlug,
        description: form.description.trim(), pricePerDay: Number(form.pricePerDay),
        ...(form.pricePerMonth ? { pricePerMonth: Number(form.pricePerMonth) } : {}),
        deposit: Number(form.deposit), stockQuantity: Number(form.stockQuantity),
        city: form.city.trim(), address: form.address.trim(),
        ...(form.latitude && form.longitude ? { latitude: Number(form.latitude), longitude: Number(form.longitude) } : {}),
        availabilityScope: form.availabilityScope, pickupTime: form.pickupTime, returnTime: form.returnTime,
        rentalModes: form.rentalModes, viewingsEnabled: form.categorySlug === "imobiliare" && form.viewingsEnabled,
        viewingPriceRon: form.categorySlug === "imobiliare" && form.viewingsEnabled ? Number(form.viewingPriceRon) : 0,
        media,
      };
      const product = await accountRequest(selected ? "productUpdate" : "productCreate", {
        method: selected ? "PATCH" : "POST",
        body: JSON.stringify(selected ? { ...payload, id: idOf(selected) } : payload),
      });
      await refresh();
      select(product);
      setNotice(selected ? "Anunțul a fost actualizat." : "Anunțul a fost publicat.");
    } catch (cause) { setError(cause.message); }
    finally { setBusy(false); }
  }

  async function addBlock(event) {
    event.preventDefault();
    if (!selected) return;
    if (!block.startDate || !block.endDate || block.endDate < block.startDate) {
      setError("Alege un interval valid pentru perioada blocată.");
      return;
    }
    setBusy(true); setError("");
    try {
      await accountRequest("availabilityBlock", { method: "POST", body: JSON.stringify({ id: idOf(selected), ...block }) });
      setBlock({ startDate: "", endDate: "", reason: "" });
      await loadAvailability(idOf(selected));
    } catch (cause) { setError(cause.message); }
    finally { setBusy(false); }
  }

  async function deleteBlock(id) {
    if (!await confirmAction({
      title: "Elimini perioada blocată?",
      description: "Intervalul va deveni din nou disponibil pentru închiriere.",
      confirmLabel: "Elimină perioada",
      destructive: true,
    })) return;
    try { await accountRequest("availabilityDelete", { method: "DELETE", body: JSON.stringify({ id }) }); await loadAvailability(idOf(selected)); }
    catch (cause) { setError(cause.message); }
  }

  const update = (field, value) => setForm((previous) => ({ ...previous, [field]: value }));
  return <>
    <Head><title>Anunțurile mele | PINLEND</title></Head>
    <AppHeader />
    <main className="mx-auto max-w-7xl px-5 py-12 md:px-8"><p className="font-mono text-xs uppercase tracking-widest text-[#30578F]">Contul meu</p><h1 className="mt-3 font-display text-4xl font-extrabold">Anunțurile mele</h1>
      
      {user && <div className="mt-8 grid gap-7 lg:grid-cols-[300px_minmax(0,1fr)]"><aside className="account-card h-fit"><button className="account-button w-full" onClick={() => select(null)} type="button">+ Adaugă anunț</button><div className="mt-5 space-y-2">{listings.map((item) => <button className={`w-full rounded-xl p-3 text-left hover:bg-[#E7F0FD] ${idOf(item) === idOf(selected) ? "bg-[#E7F0FD]" : ""}`} key={idOf(item)} onClick={() => select(item)} type="button"><span className="block truncate font-bold">{item.title}</span><span className="text-xs text-[#626977]">{item.city} · {item.isAvailable ? "Disponibil" : "Indisponibil"}</span></button>)}</div></aside>
      <div className="space-y-6"><form className="account-card scroll-mt-28" id="listing-editor" onSubmit={save}><h2 className="text-2xl font-extrabold">{selected ? "Editează anunțul" : "Publică un anunț"}</h2><div className="mt-6 grid gap-5 sm:grid-cols-2">
        <Field label="Titlu"><Input className="account-input" required value={form.title} onChange={(e) => update("title", e.target.value)} /></Field>
        <Field label="Categorie"><FormSelect className="account-input" required value={form.categorySlug} onChange={(e) => update("categorySlug", e.target.value)}><option value="">Alege categoria</option>{categories.map((item) => <option key={item.slug} value={item.slug}>{item.name}</option>)}</FormSelect></Field>
        <div className="sm:col-span-2"><Field label="Descriere"><Textarea className="account-input min-h-32" required value={form.description} onChange={(e) => update("description", e.target.value)} /></Field></div>
        <Field label="Preț pe zi (RON)"><Input className="account-input" min="1" required type="number" value={form.pricePerDay} onChange={(e) => update("pricePerDay", e.target.value)} /></Field>
        <Field label="Preț pe lună (RON)"><Input className="account-input" min="1" type="number" value={form.pricePerMonth} onChange={(e) => update("pricePerMonth", e.target.value)} /></Field>
        <Field label="Garanție (RON)"><Input className="account-input" min="0" required type="number" value={form.deposit} onChange={(e) => update("deposit", e.target.value)} /></Field>
        <Field label="Număr unități"><Input className="account-input" min="1" required type="number" value={form.stockQuantity} onChange={(e) => update("stockQuantity", e.target.value)} /></Field>
        <Field label="Oraș"><Input className="account-input" required value={form.city} onChange={(e) => update("city", e.target.value)} /></Field>
        <Field label="Adresă"><Input className="account-input" required value={form.address} onChange={(e) => update("address", e.target.value)} /></Field>
        <Field label="Latitudine (opțional)"><Input className="account-input" step="any" type="number" value={form.latitude} onChange={(e) => update("latitude", e.target.value)} /></Field>
        <Field label="Longitudine (opțional)"><Input className="account-input" step="any" type="number" value={form.longitude} onChange={(e) => update("longitude", e.target.value)} /></Field>
        <div className="sm:col-span-2"><button aria-expanded={showLocationMap} className="inline-flex items-center gap-2 text-sm font-bold text-[#30578F]" onClick={() => setShowLocationMap((current) => !current)} type="button"><span aria-hidden="true" className="material-symbols-outlined text-lg">map</span>{showLocationMap ? "Ascunde harta" : "Alege locația pe hartă"}</button>{showLocationMap && <><p className="mt-2 text-sm text-[#626977]">Apasă pe hartă pentru a seta poziția anunțului.</p><PinlendMap className="mt-3 h-80 w-full" onMapClick={({ latitude, longitude }) => setForm((current) => ({ ...current, latitude: latitude.toFixed(6), longitude: longitude.toFixed(6) }))} points={pickerPoints} selectedId="listing-location" /></>}</div>
        <Field label="Disponibilitate"><FormSelect className="account-input" value={form.availabilityScope} onChange={(e) => update("availabilityScope", e.target.value)}><option value="local">Locală</option><option value="national">Națională</option></FormSelect></Field>
        <div className="grid grid-cols-2 gap-3"><RentalTimeField label="Predare" onChange={(value) => update("pickupTime", value)} value={form.pickupTime} /><RentalTimeField label="Retur" onChange={(value) => update("returnTime", value)} value={form.returnTime} /></div>
        <fieldset className="sm:col-span-2"><legend className="text-sm font-bold">Durate permise</legend><div className="mt-2 flex gap-5">{[["hour", "Oră"], ["day", "Zi"], ["month", "Lună"]].map(([value, label]) => <label className="flex items-center gap-2" key={value}><Checkbox checked={form.rentalModes.includes(value)} onCheckedChange={(checked) => update("rentalModes", checked ? [...form.rentalModes, value] : form.rentalModes.filter((item) => item !== value))} />{label}</label>)}</div></fieldset>
        {form.categorySlug === "imobiliare" && <div className="sm:col-span-2"><label className="flex gap-2 font-bold"><Checkbox checked={form.viewingsEnabled} onCheckedChange={(checked) => update("viewingsEnabled", checked === true)} />Permite vizionări</label>{form.viewingsEnabled && <Field label="Preț vizionare (RON)"><Input className="account-input max-w-48" min="0" type="number" value={form.viewingPriceRon} onChange={(e) => update("viewingPriceRon", e.target.value)} /></Field>}</div>}
        <div className="sm:col-span-2"><p className="text-sm font-bold">Fotografii și video ({media.length}/8)</p><div className="mt-3 flex flex-wrap gap-3">{media.map((item) => <div className="relative" key={item.key}>{item.type === "video" ? <video className="h-20 w-20 rounded-xl object-cover" src={item.url} /> : <img alt={item.alt} className="h-20 w-20 rounded-xl object-cover" src={item.url} />}<button aria-label="Elimină fișierul" className="absolute -right-2 -top-2 rounded-full bg-black px-2 text-white" onClick={() => setMedia((current) => current.filter((image) => image.key !== item.key))} type="button">×</button></div>)}</div><Input accept="image/jpeg,image/png,image/webp,video/mp4,video/quicktime" className="mt-3 text-sm" disabled={busy || media.length >= 8} multiple onChange={uploadMedia} type="file" /></div>
      </div><button className="account-button mt-7" disabled={busy || form.rentalModes.length === 0} type="submit">{busy ? "Se salvează..." : selected ? "Salvează modificările" : "Publică anunțul"}</button></form>
      {selected && <section className="account-card"><h2 className="text-xl font-extrabold">Disponibilitate și perioade blocate</h2><p className="mt-2 text-sm text-[#626977]">Blochează zilele în care nu poți preda obiectul.</p><form className="mt-5 grid items-end gap-3 sm:grid-cols-[1fr_1fr_1fr_auto]" onSubmit={addBlock}><RentalDateField label="De la" onChange={(value) => setBlock({ ...block, startDate: value, endDate: block.endDate < value ? "" : block.endDate })} value={block.startDate} /><RentalDateField label="Până la" min={block.startDate} onChange={(value) => setBlock({ ...block, endDate: value })} value={block.endDate} /><Input aria-label="Motiv" className="account-input mt-0" placeholder="Motiv (opțional)" value={block.reason} onChange={(e) => setBlock({ ...block, reason: e.target.value })} /><button className="account-button" disabled={busy} type="submit">Blochează</button></form><div className="mt-5 space-y-2">{availability?.manualBlocks?.map((item) => <div className="flex items-center justify-between rounded-xl bg-[#F3F3F3] p-3" key={idOf(item)}><span className="text-sm">{String(item.startDate).slice(0, 10)} – {String(item.endDate).slice(0, 10)} {item.reason && `· ${item.reason}`}</span><button className="font-bold text-red-700" onClick={() => deleteBlock(idOf(item))} type="button">Elimină</button></div>)}{availability?.manualBlocks?.length === 0 && <p className="text-sm text-[#626977]">Nu ai perioade blocate.</p>}</div></section>}
      </div></div>}
    </main>
  </>;
}

function Field({ label, children }) { return <label className="block text-sm font-bold">{label}{children}</label>; }
