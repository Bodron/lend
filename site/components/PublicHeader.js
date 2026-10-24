import Link from "next/link";
import { useState } from "react";
import { useRouter } from "next/router";
import BrandLogo from "./BrandLogo";
import LanguageSwitcher from "./LanguageSwitcher";
import { translations } from "../lib/i18n";
import AccountAvatarLink from "./AccountAvatarLink";

const menuLinks = [
  { key: "listings", href: "/" },
  { key: "about", href: "/despre-noi" },
  { key: "features", href: "/features" },
  { key: "download", href: "/download" },
];

export default function PublicHeader({ current = "" }) {
  const [menuOpen, setMenuOpen] = useState(false);
  const { locale } = useRouter();
  const t = translations(locale);

  return <>
    <header className="fixed top-0 z-50 w-full bg-[#f9f9f9]/20 backdrop-blur-md transition-all duration-500 hover:bg-[#f9f9f9]">
      <div className="flex h-20 w-full items-center justify-between gap-2 px-4 sm:px-5 md:px-20">
        <div className="shrink-0 [&_img]:!h-6 sm:[&_img]:!h-9"><BrandLogo /></div>
        <nav aria-label={t.navigation} className="flex items-center gap-[clamp(2rem,5vw,6rem)]">
          <Link aria-current={current === "/" ? "page" : undefined} className="hidden font-mono text-xs uppercase tracking-widest text-[#444748] hover:text-black lg:inline" href="/">
            {t.listings}
          </Link>
          <button aria-expanded={menuOpen} aria-label="Deschide meniul" className="group flex items-center gap-3 font-mono text-xs uppercase tracking-widest text-black" onClick={() => setMenuOpen(true)} type="button">
            <span className="h-px w-6 bg-black transition-all group-hover:w-8 sm:w-8 sm:group-hover:w-12" />
            <span className="hidden sm:inline">{t.menu}</span>
          </button>
        </nav>
        <div className="flex shrink-0 items-center gap-2 md:gap-6">
        <LanguageSwitcher />
        <AccountAvatarLink label={t.account} />
        </div>
      </div>
    </header>
    <div aria-hidden={!menuOpen} className={`mega-menu-overlay fixed inset-0 z-[60] flex flex-col justify-center bg-black px-5 md:px-20 ${menuOpen ? "mega-menu-open" : ""}`}>
      <button className="absolute right-6 top-8 flex items-center gap-2 font-mono text-xs uppercase tracking-widest text-white md:right-10 md:top-10" onClick={() => setMenuOpen(false)} type="button">
        <span className="material-symbols-outlined">close</span>
        {t.close}
      </button>
      <nav aria-label="Meniu" className="flex flex-col space-y-6">
        {menuLinks.map(({ key, href }) => <Link className={`font-display text-5xl font-bold transition-all duration-300 md:text-7xl ${current === href ? "text-[#8FABD4]" : "text-white hover:text-[#8FABD4]"}`} href={href} key={href} onClick={() => setMenuOpen(false)} tabIndex={menuOpen ? 0 : -1}>{t[key]}</Link>)}
      </nav>
    </div>
  </>;
}
