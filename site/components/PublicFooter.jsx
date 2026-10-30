import Link from "next/link";
import { useRouter } from "next/router";
import { translations } from "../lib/i18n";

export default function PublicFooter() {
  const en = useRouter().locale === "en";
  const t = translations(en ? "en" : "ro");

  return <footer className="w-full bg-black px-5 py-24 text-white md:px-20 md:py-32">
    <div className="mb-12 flex flex-col items-start justify-between gap-8 border-b border-white/10 pb-12 lg:flex-row lg:items-end">
      <h2 className="font-display text-5xl font-extrabold uppercase leading-none md:text-7xl">{en ? "Ready to share?" : "Gata sa imparti?"}</h2>
      <Link className="bg-[#4A70A9] px-10 py-5 font-mono text-xs uppercase tracking-widest transition-colors hover:bg-white hover:text-[#30578F]" href="/download">{en ? "Get started" : "Incepe acum"}</Link>
    </div>
    <div className="grid gap-10 md:grid-cols-3">
      <div className="flex flex-col gap-3"><p className="mb-2 font-mono text-xs uppercase tracking-widest text-white/60">{en ? "Explore" : "Navigare"}</p>
        <Link href="/">{t.listings}</Link><Link href="/despre-noi">{t.about}</Link><Link href="/features">{t.features}</Link><Link href="/download">{t.download}</Link>
      </div>
      <div className="flex flex-col gap-3"><p className="mb-2 font-mono text-xs uppercase tracking-widest text-white/60">{en ? "Legal" : "Legal"}</p>
        <Link href="/privacy-policy">{en ? "Privacy policy" : "Politica de confidentialitate"}</Link>
        <Link href="/terms-and-conditions">{en ? "Terms and conditions" : "Termeni si conditii"}</Link>
        <Link href="/cookie-policy">{en ? "Cookie policy" : "Politica de cookies"}</Link>
        <Link href="/account-deletion">{en ? "Delete account" : "Stergere cont"}</Link>
      </div>
      <div className="flex flex-col gap-3"><p className="mb-2 font-mono text-xs uppercase tracking-widest text-white/60">{en ? "Contact" : "Contact"}</p>
        <a href="mailto:support@pinfers.com">support@pinfers.com</a><Link href="/support">{en ? "Support" : "Suport"}</Link>
      </div>
    </div>
    <p className="mt-14 border-t border-white/10 pt-6 font-mono text-xs text-white/50">© 2026 PINLEND. {en ? "Made for the sharing economy." : "Creat pentru economia colaborativa."}</p>
  </footer>;
}
