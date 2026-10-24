import { useState } from "react";
import { ro } from "date-fns/locale";
import { CalendarDays, ChevronDown, Clock3, Minus, Plus } from "lucide-react";
import { Button } from "./ui/button";
import { Calendar } from "./ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "./ui/popover";

const dateFormatter = new Intl.DateTimeFormat("ro-RO", { day: "2-digit", month: "long", year: "numeric" });
const twoDigits = (value) => String(value).padStart(2, "0");
const dateFromKey = (key) => key ? new Date(`${key}T12:00:00`) : undefined;
const dateKey = (date) => `${date.getFullYear()}-${twoDigits(date.getMonth() + 1)}-${twoDigits(date.getDate())}`;
const minutesOf = (value) => Number(value.slice(0, 2)) * 60 + Number(value.slice(3, 5));

export function RentalDateField({ label, value, min, onChange, disabled = false }) {
  const [open, setOpen] = useState(false);
  const selected = dateFromKey(value);
  const minimum = dateFromKey(min);

  return <div className="min-w-0">
    <span className="mb-2 block text-sm font-bold">{label}</span>
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          aria-label={label}
          className="h-12 w-full justify-between rounded-xl border-[#C3C6D1] px-4 text-left text-sm font-medium hover:bg-[#F5F8FD]"
          disabled={disabled}
          type="button"
          variant="outline"
        >
          <span className={selected ? "text-[#1B1B1B]" : "text-[#69717E]"}>{selected ? dateFormatter.format(selected) : "Alege data"}</span>
          <CalendarDays aria-hidden="true" className="size-4 text-[#30578F]" />
        </Button>
      </PopoverTrigger>
      <PopoverContent align="start" className="w-auto max-w-[calc(100vw-2rem)] p-1">
        <Calendar
          key={value || min}
          className="[--cell-size:2.5rem]"
          defaultMonth={selected || minimum}
          disabled={minimum ? { before: minimum } : undefined}
          locale={ro}
          mode="single"
          onSelect={(date) => { if (date) { onChange(dateKey(date)); setOpen(false); } }}
          selected={selected}
          showOutsideDays={false}
          weekStartsOn={1}
        />
      </PopoverContent>
    </Popover>
  </div>;
}

export function RentalTimeField({ label, value, min = "00:00", max = "23:59", onChange, disabled = false }) {
  const [open, setOpen] = useState(false);
  const first = minutesOf(min);
  const last = minutesOf(max);
  const hour = Number(value.slice(0, 2));
  const minute = Number(value.slice(3, 5));
  const current = minutesOf(value);
  const hours = Array.from({ length: 24 }, (_, index) => index).filter((option) => option * 60 + 59 >= first && option * 60 <= last);
  const minuteChoices = [0, 15, 30, 45]
    .filter((option) => hour * 60 + option >= first && hour * 60 + option <= last);

  function changeHour(nextHour) {
    const earliest = Math.max(first, nextHour * 60);
    const latest = Math.min(last, nextHour * 60 + 59);
    const nextMinutes = Math.min(latest, Math.max(earliest, nextHour * 60 + minute));
    onChange(`${twoDigits(nextHour)}:${twoDigits(nextMinutes % 60)}`);
  }

  return <div className="min-w-0">
    <span className="mb-2 block text-sm font-bold">{label}</span>
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button aria-label={`${label}: ${value}`} className="h-12 w-full justify-between rounded-xl border-[#C3C6D1] px-4 text-sm font-semibold hover:bg-[#F5F8FD]" disabled={disabled} type="button" variant="outline">
          <span className="flex items-center gap-3"><Clock3 aria-hidden="true" className="size-4 text-[#30578F]" />{value}</span>
          <ChevronDown aria-hidden="true" className="size-4 text-[#69717E]" />
        </Button>
      </PopoverTrigger>
      <PopoverContent align="start" className="w-80 max-w-[calc(100vw-2rem)] gap-0 p-4">
        <div className="flex items-center justify-between"><span className="text-sm font-bold">{label}</span><span className="rounded-lg bg-[#E7F0FD] px-3 py-1 font-bold text-[#30578F]">{value}</span></div>
        <p className="mb-2 mt-4 text-xs font-semibold uppercase tracking-wider text-[#69717E]">Ora</p>
        <div className="grid grid-cols-6 gap-1.5">
          {hours.map((option) => <Button aria-label={`Ora ${twoDigits(option)}`} aria-pressed={hour === option} className="h-9 rounded-lg px-0" key={option} onClick={() => changeHour(option)} size="sm" type="button" variant={hour === option ? "default" : "ghost"}>{twoDigits(option)}</Button>)}
        </div>
        <p className="mb-2 mt-4 text-xs font-semibold uppercase tracking-wider text-[#69717E]">Minute</p>
        <div className="grid grid-cols-4 gap-1.5">
          {minuteChoices.map((option) => <Button aria-label={`${option} minute`} aria-pressed={minute === option} className="h-9 rounded-lg px-0" key={option} onClick={() => onChange(`${twoDigits(hour)}:${twoDigits(option)}`)} size="sm" type="button" variant={minute === option ? "default" : "ghost"}>{twoDigits(option)}</Button>)}
        </div>
        <div className="mt-4 flex items-center justify-between border-t border-black/10 pt-3">
          <span className="text-xs text-[#69717E]">Ajustare cu 1 minut</span>
          <div className="flex items-center gap-1">
            <Button aria-label="Cu un minut mai devreme" className="size-8 rounded-lg" disabled={current <= first} onClick={() => onChange(`${twoDigits(Math.floor((current - 1) / 60))}:${twoDigits((current - 1) % 60)}`)} size="icon" type="button" variant="outline"><Minus className="size-4" /></Button>
            <Button aria-label="Cu un minut mai târziu" className="size-8 rounded-lg" disabled={current >= last} onClick={() => onChange(`${twoDigits(Math.floor((current + 1) / 60))}:${twoDigits((current + 1) % 60)}`)} size="icon" type="button" variant="outline"><Plus className="size-4" /></Button>
          </div>
        </div>
        <Button className="mt-3 h-9 w-full rounded-full font-bold" onClick={() => setOpen(false)} type="button">Gata</Button>
      </PopoverContent>
    </Popover>
  </div>;
}

export function RentalDateTimeField({ label, value = "", min = "", onChange, disabled = false }) {
  const [date = "", time = ""] = value.split("T");
  const [minDate = "", minTime = "00:00"] = min.split("T");
  const earliestTime = date === minDate ? minTime : "00:00";

  return <div className="grid min-w-0 gap-3 sm:grid-cols-2">
    <RentalDateField
      disabled={disabled}
      label={`${label} · data`}
      min={minDate}
      onChange={(nextDate) => {
        const nextMinimum = nextDate === minDate ? minTime : "00:00";
        const nextTime = time && time >= nextMinimum ? time : nextMinimum === "00:00" ? "10:00" : nextMinimum;
        onChange(`${nextDate}T${nextTime}`);
      }}
      value={date}
    />
    <RentalTimeField
      disabled={disabled || !date}
      label={`${label} · ora`}
      min={earliestTime}
      onChange={(nextTime) => onChange(`${date}T${nextTime}`)}
      value={time || "10:00"}
    />
  </div>;
}
