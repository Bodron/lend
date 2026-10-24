import { useRouter } from "next/router";
import { Globe2 } from "lucide-react";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { translations } from "../lib/i18n";

export default function LanguageSwitcher({ dark = false }) {
  const router = useRouter();
  const locale = router.locale || "ro";
  const t = translations(locale);

  function changeLanguage(nextLocale) {
    if (nextLocale === locale) return;
    document.cookie = `NEXT_LOCALE=${nextLocale}; path=/; max-age=31536000; samesite=lax`;
    router.push({ pathname: router.pathname, query: router.query }, router.asPath, { locale: nextLocale });
  }

  return <Select onValueChange={changeLanguage} value={locale}>
    <SelectTrigger
      aria-label={t.language}
      className={`h-9 min-w-21 gap-2 rounded-full border-0 px-3 font-mono text-[11px] font-semibold tracking-wider shadow-none transition-colors focus-visible:border-0 focus-visible:ring-2 focus-visible:ring-[#30578F]/30 ${dark ? "bg-white/10 text-white hover:bg-white/20" : "bg-transparent text-[#1a1a1a] hover:bg-[#E7F0FD]"}`}
    >
      <Globe2 aria-hidden="true" className="size-4 text-[#4A70A9]" />
      <SelectValue>{locale.toUpperCase()}</SelectValue>
    </SelectTrigger>
    <SelectContent align="end" className="z-[100] min-w-40 rounded-xl border border-black/10 bg-white p-1 shadow-xl" position="popper">
      <SelectItem className="rounded-lg py-2.5 text-sm" value="ro">Română · RO</SelectItem>
      <SelectItem className="rounded-lg py-2.5 text-sm" value="en">English · EN</SelectItem>
    </SelectContent>
  </Select>;
}
