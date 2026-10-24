import Link from "next/link";
import { useRouter } from "next/router";
import { useEffect, useRef } from "react";
import BrandLogo from "./BrandLogo";
import LanguageSwitcher from "./LanguageSwitcher";
import { translations } from "../lib/i18n";
import { useAccountProfile } from "./AccountProfileProvider";
import UserAvatar from "./UserAvatar";

const links = [
  { key: "listings", href: "/", paths: ["/", "/anunt", "/inchiriaza"] },
  { key: "messages", href: "/mesaje", paths: ["/mesaje"] },
  { key: "viewings", href: "/vizionari", paths: ["/vizionari"] },
  { key: "findRoommate", href: "/colegi", paths: ["/colegi"] },
  { key: "favorites", href: "/favorite", paths: ["/favorite"] },
  { key: "notifications", href: "/notificari", paths: ["/notificari"] },
  { key: "account", href: "/account", paths: ["/account", "/anunturile-mele", "/retur"] },
];

function NavLinks({ mobile, pathname, profile, t }) {
  return links.map(({ key, href, paths }) => {
    const active = paths.some((path) => pathname === path || pathname.startsWith(`${path}/`));
    return <Link
      aria-current={active ? "page" : undefined}
      className={`flex shrink-0 items-center border-b-2 font-bold transition-colors ${mobile ? "h-12 text-xs" : "h-20 text-sm"} ${active ? "border-[#30578F] text-[#30578F]" : "border-transparent text-[#434750] hover:border-black/30 hover:text-black"}`}
      href={href}
      key={href}
    >{key === "account" && <UserAvatar className="mr-1 size-6" user={profile} />}{t[key]}</Link>;
  });
}

export default function AppHeader() {
  const { pathname, locale } = useRouter();
  const { profile } = useAccountProfile();
  const t = translations(locale);
  const mobileNav = useRef(null);
  useEffect(() => {
    const nav = mobileNav.current;
    const active = nav?.querySelector('[aria-current="page"]');
    if (nav && active) {
      nav.scrollLeft += active.getBoundingClientRect().left - nav.getBoundingClientRect().left - (nav.clientWidth - active.clientWidth) / 2;
    }
  }, [pathname]);
  return <header className="sticky top-0 z-50 border-b border-black/10 bg-white/95 backdrop-blur-md">
    <div className="mx-auto flex h-20 max-w-7xl items-center justify-between px-5 md:px-8">
      <BrandLogo />
      <div className="hidden items-center gap-4 xl:flex">
        <nav aria-label={t.navigation} className="flex items-center gap-4 xl:gap-6">
          <NavLinks pathname={pathname} profile={profile} t={t} />
        </nav>
        <LanguageSwitcher />
      </div>
      <div className="xl:hidden">
        <LanguageSwitcher />
      </div>
    </div>
    <nav aria-label={t.navigation} className="flex gap-6 overflow-x-auto border-t border-black/5 px-5 [scrollbar-width:none] md:px-8 xl:hidden [&::-webkit-scrollbar]:hidden" ref={mobileNav}>
      <NavLinks mobile pathname={pathname} profile={profile} t={t} />
    </nav>
  </header>;
}
