import { useEffect, useState } from "react";
import { useRouter } from "next/router";
import { Dialog } from "radix-ui";
import { enGB, ro } from "date-fns/locale";
import { CalendarDays, CalendarRange, Clock3, X } from "lucide-react";
import { Calendar } from "./ui/calendar";

const pad = (value) => String(value).padStart(2, "0");
const dateKey = (date) => `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
const addDays = (date, days) => new Date(date.getFullYear(), date.getMonth(), date.getDate() + days);
const addMonth = (date) => new Date(date.getFullYear(), date.getMonth() + 1, Math.min(date.getDate(), new Date(date.getFullYear(), date.getMonth() + 2, 0).getDate()));
const minutes = (value) => Number(value.slice(0, 2)) * 60 + Number(value.slice(3, 5));
const isoDate = (date, time = "00:00") => `${dateKey(date)}T${time}:00.000Z`;

const copy = {
  ro: {
    title: "Trimite o ofertă", close: "Închide", loading: "Se încarcă anunțul...",
    modes: "Alege modul de închiriere", period: "Alege perioada", price: "Verifică oferta",
    hour: "Pe ore", day: "Pe zile", month: "Pe lună", next: "Continuă", back: "Înapoi", send: "Trimite oferta",
    oneDay: "Poți alege o singură zi sau un interval.", pickDay: "Alege o zi și, opțional, ultima zi.",
    start: "De la", end: "Până la", pickup: "Ridicare", return: "Retur",
    normal: "Preț normal pentru perioada aleasă", amount: "Suma propusă de tine", amountPlaceholder: "Introdu suma",
    invalidTime: "Alege ore viitoare, cu returul după ridicare.", noModes: "Anunțul nu are un mod de închiriere disponibil.",
    invalidAmount: "Introdu o sumă întreagă mai mare decât zero.", loadError: "Nu am putut încărca anunțul.",
  },
  en: {
    title: "Make an offer", close: "Close", loading: "Loading listing...",
    modes: "Choose rental type", period: "Choose dates", price: "Review your offer",
    hour: "Hourly", day: "Daily", month: "Monthly", next: "Continue", back: "Back", send: "Send offer",
    oneDay: "Choose one day or a date range.", pickDay: "Choose a first day and optionally a last day.",
    start: "From", end: "Until", pickup: "Pickup", return: "Return",
    normal: "Regular price for this period", amount: "Your offer", amountPlaceholder: "Enter amount",
    invalidTime: "Choose future hours, with return after pickup.", noModes: "This listing has no available rental type.",
    invalidAmount: "Enter a whole amount greater than zero.", loadError: "Could not load the listing.",
  },
};

export default function OfferComposer({ productSlug, onClose, onSubmit }) {
  const { locale } = useRouter();
  const t = copy[locale] || copy.ro;
  const [product, setProduct] = useState(null);
  const [loadError, setLoadError] = useState("");
  const [step, setStep] = useState(0);
  const [mode, setMode] = useState(null);
  const [range, setRange] = useState(undefined);
  const [day, setDay] = useState(undefined);
  const [pickup, setPickup] = useState("");
  const [returnTime, setReturnTime] = useState("");
  const [amount, setAmount] = useState("");
  const [sending, setSending] = useState(false);
  const [submitError, setSubmitError] = useState("");
  const [openedAt] = useState(() => new Date());

  useEffect(() => {
    let active = true;
    fetch(`/api/account/offerProduct?slug=${encodeURIComponent(productSlug)}`, { credentials: "same-origin", cache: "no-store" })
      .then(async (response) => {
        const data = await response.json().catch(() => ({}));
        if (!response.ok) throw new Error(data.message || t.loadError);
        return data;
      })
      .then((data) => {
        if (!active) return;
        setProduct(data);
        setPickup(data.pickupTime || "10:00");
        setReturnTime(data.returnTime || "18:00");
      })
      .catch((error) => { if (active) setLoadError(error.message); });
    return () => { active = false; };
  }, [productSlug, t.loadError]);

  const today = openedAt;
  const firstDate = addDays(today, mode === "hour" ? 0 : 1);
  const lastDate = new Date(today.getFullYear() + 2, 11, 31);
  const modes = (product?.rentalModes || [])
    .filter((item) => ["hour", "day", "month"].includes(item))
    .filter((item) => item !== "month" || Number(product?.pricePerMonth) > 0);
  const start = mode === "day" ? range?.from : day;
  const lastDay = mode === "day" ? range?.to || range?.from : day;
  const end = start && lastDay ? mode === "hour" ? start : mode === "month" ? addMonth(start) : addDays(lastDay, 1) : null;
  const hourValid = mode !== "hour" || (start && minutes(returnTime) > minutes(pickup)
    && new Date(`${dateKey(start)}T${pickup}:00`).getTime() > openedAt.getTime());
  const periodValid = Boolean(start && end && hourValid && dateKey(start) >= dateKey(firstDate) && dateKey(start) <= dateKey(lastDate));
  const formatDate = (date) => new Intl.DateTimeFormat(locale === "en" ? "en-GB" : "ro-RO", { day: "numeric", month: "short", year: "numeric" }).format(date);
  const dayCount = start && end ? Math.round((Date.UTC(end.getFullYear(), end.getMonth(), end.getDate()) - Date.UTC(start.getFullYear(), start.getMonth(), start.getDate())) / 86400000) : 0;
  const normalPrice = mode === "month" ? Number(product?.pricePerMonth || 0)
    : mode === "hour" ? Math.ceil((minutes(returnTime) - minutes(pickup)) / 60) * Math.max(1, Math.round(Number(product?.pricePerDay || 0) / 8))
      : dayCount * Number(product?.pricePerDay || 0);
  const proposed = Number(amount);
  const amountValid = Number.isSafeInteger(proposed) && proposed > 0;
  const minimumMinutes = minutes(product?.pickupTime || "10:00");
  const maximumMinutes = minutes(product?.returnTime || "18:00");
  const timeChoices = Array.from(new Set([minimumMinutes, maximumMinutes, ...Array.from({ length: 48 }, (_, index) => index * 30)]))
    .filter((value) => value >= minimumMinutes && value <= maximumMinutes)
    .sort((a, b) => a - b)
    .map((value) => `${pad(Math.floor(value / 60))}:${pad(value % 60)}`);

  async function submit(event) {
    event.preventDefault();
    if (!periodValid || !amountValid || sending) {
      if (!amountValid) setSubmitError(t.invalidAmount);
      return;
    }
    setSending(true);
    setSubmitError("");
    try {
      if (new Date(`${dateKey(start)}T${mode === "hour" ? pickup : "00:00"}:00`).getTime() <= Date.now()) {
        throw new Error(t.invalidTime);
      }
      await onSubmit({
        amount: proposed,
        stockQuantity: Math.max(1, Number(product.stockQuantity) || 1),
        rentalMode: mode,
        startDate: isoDate(start, mode === "hour" ? pickup : "00:00"),
        endDate: isoDate(end, mode === "hour" ? returnTime : "00:00"),
      });
    } catch (error) {
      setSubmitError(error.message);
      setSending(false);
    }
  }

  return <Dialog.Root onOpenChange={(open) => { if (!open) onClose(); }} open>
    <Dialog.Portal>
      <Dialog.Overlay className="fixed inset-0 z-50 bg-black/45 backdrop-blur-[2px]" />
      <Dialog.Content className="fixed left-1/2 top-1/2 z-50 flex max-h-[min(90dvh,820px)] w-[min(94vw,560px)] -translate-x-1/2 -translate-y-1/2 flex-col overflow-hidden rounded-[24px] bg-white text-[#1B1B1B] shadow-2xl outline-none">
        <header className="flex items-start justify-between gap-4 border-b border-black/10 px-6 py-5">
          <div><p className="font-mono text-[11px] uppercase tracking-[0.2em] text-[#30578F]">PINLEND · {step + 1}/3</p><Dialog.Title className="mt-1 font-display text-2xl font-extrabold">{t.title}</Dialog.Title><Dialog.Description className="mt-1 text-sm text-[#626977]">{[t.modes, t.period, t.price][step]}</Dialog.Description></div>
          <Dialog.Close aria-label={t.close} className="rounded-full p-2 text-[#626977] hover:bg-[#F1F3F6]" type="button"><X className="size-5" /></Dialog.Close>
        </header>
        <form className="min-h-0 overflow-y-auto" onSubmit={submit}>
          <div className="space-y-5 px-6 py-5">
            {!product && !loadError && <p className="py-14 text-center text-sm text-[#626977]">{t.loading}</p>}
            {loadError && <p className="rounded-xl bg-red-50 p-4 text-sm text-red-700">{loadError}</p>}
            {product && modes.length === 0 && <p className="rounded-xl bg-amber-50 p-4 text-sm text-amber-800">{t.noModes}</p>}
            {product && step === 0 && modes.map((item) => {
              const Icon = item === "hour" ? Clock3 : item === "month" ? CalendarRange : CalendarDays;
              return <button className="flex w-full items-center gap-4 rounded-2xl border border-[#DCE2EB] p-4 text-left transition-colors hover:border-[#30578F] hover:bg-[#F2F6FC]" key={item} onClick={() => { setMode(item); setDay(undefined); setRange(undefined); setStep(1); }} type="button"><span className="flex size-11 items-center justify-center rounded-xl bg-[#E7F0FD] text-[#30578F]"><Icon className="size-5" /></span><span className="font-bold">{t[item]}</span><span className="ml-auto text-xl text-[#8C96A5]">›</span></button>;
            })}
            {product && step === 1 && <>
              <p className="text-sm text-[#626977]">{mode === "day" ? t.pickDay : mode === "month" ? t.start : t.period}</p>
              <div className="flex justify-center rounded-2xl border border-[#DCE2EB] bg-[#FAFBFD] p-2 sm:p-3" style={{ "--primary": "#30578F", "--primary-foreground": "#FFFFFF" }}>
                {mode === "day" ? <Calendar className="[--cell-size:2.6rem]" defaultMonth={firstDate} disabled={{ before: firstDate, after: lastDate }} endMonth={lastDate} locale={locale === "en" ? enGB : ro} mode="range" onSelect={setRange} selected={range} showOutsideDays={false} startMonth={firstDate} weekStartsOn={1} />
                  : <Calendar className="[--cell-size:2.6rem]" defaultMonth={firstDate} disabled={{ before: firstDate, after: lastDate }} endMonth={lastDate} locale={locale === "en" ? enGB : ro} mode="single" onSelect={setDay} selected={day} showOutsideDays={false} startMonth={firstDate} weekStartsOn={1} />}
              </div>
              {mode === "day" && <p className="text-xs text-[#626977]">{t.oneDay}</p>}
              {mode === "hour" && <div className="grid grid-cols-2 gap-3">{[[t.pickup, pickup, setPickup], [t.return, returnTime, setReturnTime]].map(([label, value, change]) => <label className="text-sm font-bold" key={label}>{label}<select className="mt-2 h-12 w-full rounded-xl border border-[#C3C6D1] bg-white px-3 font-medium" onChange={(event) => change(event.target.value)} value={value}>{timeChoices.map((option) => <option key={option} value={option}>{option}</option>)}</select></label>)}</div>}
              {start && end && <div className="rounded-xl bg-[#E7F0FD] px-4 py-3 text-sm font-semibold text-[#30578F]">{formatDate(start)}{mode === "hour" ? ` · ${pickup}–${returnTime}` : ` – ${formatDate(mode === "day" ? lastDay : end)}`}</div>}
              {start && !hourValid && <p className="text-sm text-red-700">{t.invalidTime}</p>}
            </>}
            {product && step === 2 && <>
              <div className="rounded-2xl border border-[#DCE2EB] bg-[#FAFBFD] p-4"><p className="text-sm font-bold">{formatDate(start)}{mode === "hour" ? ` · ${pickup}–${returnTime}` : ` – ${formatDate(mode === "day" ? lastDay : end)}`}</p><p className="mt-3 text-xs text-[#626977]">{t.normal}</p><p className="mt-1 text-2xl font-extrabold text-[#30578F]">{normalPrice} RON</p></div>
              <label className="block text-sm font-bold" htmlFor="offer-amount">{t.amount}</label>
              <div className="flex h-14 items-center rounded-xl border border-[#C3C6D1] bg-white px-4 focus-within:border-[#30578F] focus-within:ring-2 focus-within:ring-[#30578F]/15"><input autoFocus className="min-w-0 flex-1 bg-transparent text-lg font-bold outline-none placeholder:text-[#9BA3AF]" id="offer-amount" inputMode="numeric" min="1" onChange={(event) => setAmount(event.target.value)} placeholder={t.amountPlaceholder} required step="1" type="number" value={amount} /><span className="font-bold text-[#626977]">RON</span></div>
              {submitError && <p className="rounded-xl bg-red-50 p-3 text-sm text-red-700" role="alert">{submitError}</p>}
            </>}
          </div>
          {product && step > 0 && <footer className="sticky bottom-0 flex items-center gap-3 border-t border-black/10 bg-white px-6 py-4"><button className="rounded-xl px-4 py-3 text-sm font-bold text-[#30578F] hover:bg-[#F2F6FC]" onClick={() => { setSubmitError(""); setStep(step - 1); }} type="button">{t.back}</button><button className="ml-auto rounded-xl bg-[#30578F] px-6 py-3 text-sm font-bold text-white disabled:cursor-not-allowed disabled:opacity-45" disabled={step === 1 ? !periodValid : !amountValid || sending} onClick={step === 1 ? () => setStep(2) : undefined} type={step === 2 ? "submit" : "button"}>{step === 2 ? t.send : t.next}</button></footer>}
        </form>
      </Dialog.Content>
    </Dialog.Portal>
  </Dialog.Root>;
}
