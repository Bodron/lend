import Head from "next/head";
import Link from "next/link";
import { useEffect, useState } from "react";

const navLinks = [
  { label: "Acasa", href: "/" },
  { label: "Functionalitati", href: "/features" },
  { label: "Comunitate", href: "/community" },
  { label: "Arhiva", href: "/archive" },
  { label: "Descarca", href: "/download" },
];

export default function LegalLayout({ title, description, eyebrow, updated, children }) {
  const [menuOpen, setMenuOpen] = useState(false);
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const handleScroll = () => {
      const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
      setProgress(maxScroll > 0 ? window.scrollY / maxScroll : 0);
    };

    window.addEventListener("scroll", handleScroll, { passive: true });
    handleScroll();

    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <>
      <Head>
        <title>{title} | BorrowIt</title>
        <meta name="description" content={description} />
      </Head>

      <div
        className="fixed left-0 top-0 z-[70] h-0.5 w-full origin-left bg-[#4A70A9] transition-transform"
        style={{ transform: `scaleX(${progress})` }}
      />

      <MegaMenu open={menuOpen} onClose={() => setMenuOpen(false)} />
      <Header onMenu={() => setMenuOpen(true)} />

      <main className="bg-[#f9f9f9] px-5 pb-24 pt-36 md:px-20 md:pb-40 md:pt-48">
        <section className="mx-auto max-w-6xl">
          <p className="mb-6 flex items-center gap-4 font-mono text-xs uppercase tracking-[0.3em] text-[#4A70A9]">
            <span className="h-px w-12 bg-[#4A70A9]" />
            {eyebrow}
          </p>
          <h1 className="download-display-2xl max-w-5xl font-display font-extrabold text-black">
            {title}
          </h1>
          <p className="mt-10 max-w-2xl text-xl leading-8 text-[#444748]">{description}</p>
          <p className="mt-6 font-mono text-xs uppercase tracking-widest text-black/40">
            Ultima actualizare: {updated}
          </p>
        </section>

        <section className="mx-auto mt-20 grid max-w-6xl grid-cols-1 gap-12 lg:grid-cols-[260px_1fr]">
          <aside className="h-fit border-l border-black/10 pl-6 lg:sticky lg:top-28">
            <p className="mb-5 font-mono text-xs uppercase tracking-widest text-black/40">Pagini utile</p>
            <nav className="flex flex-col gap-3 text-base leading-6">
              <Link href="/privacy-policy">Politica de confidentialitate</Link>
              <Link href="/privacy-choices">Optiuni de confidentialitate</Link>
              <Link href="/terms-and-conditions">Termeni si conditii</Link>
              <Link href="/cookie-policy">Politica de cookies</Link>
              <Link href="/account-deletion">Stergere cont</Link>
              <Link href="/support">Suport</Link>
            </nav>
          </aside>
          <div className="legal-content min-w-0">{children}</div>
        </section>
      </main>

      <Footer />
    </>
  );
}

function Header({ onMenu }) {
  return (
    <header className="fixed top-0 z-50 w-full bg-[#f9f9f9]/20 backdrop-blur-md transition-all duration-500 hover:bg-[#f9f9f9]">
      <div className="flex h-20 w-full items-center justify-between px-5 md:px-20">
        <Link href="/" className="flex items-center gap-2" aria-label="BorrowIt">
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-black">
            <span className="material-symbols-outlined text-white">sync_alt</span>
          </div>
          <span className="font-display text-[24px] font-bold uppercase tracking-normal text-black">BorrowIt</span>
        </Link>
        <nav className="hidden items-center gap-[clamp(2rem,5vw,6rem)] lg:flex">
          <Link className="font-mono text-xs uppercase tracking-widest text-[#444748] hover:text-black" href="/archive">
            Arhiva
          </Link>
          <Link className="font-mono text-xs uppercase tracking-widest text-[#444748] hover:text-black" href="/community">
            Povesti
          </Link>
          <button className="group flex items-center gap-3 font-mono text-xs uppercase tracking-widest text-black" onClick={onMenu} type="button">
            <span className="h-px w-8 bg-black transition-all group-hover:w-12" />
            Meniu
          </button>
        </nav>
        <div className="flex h-8 w-8 items-center justify-center rounded-full bg-black">
          <span className="material-symbols-outlined text-[18px] text-white">person</span>
        </div>
      </div>
    </header>
  );
}

function MegaMenu({ open, onClose }) {
  return (
    <div className={`mega-menu-overlay fixed inset-0 z-[60] flex flex-col justify-center bg-black px-5 md:px-20 ${open ? "mega-menu-open" : ""}`} aria-hidden={!open}>
      <button className="absolute right-6 top-8 flex items-center gap-2 font-mono text-xs uppercase tracking-widest text-white md:right-10 md:top-10" onClick={onClose} type="button">
        <span className="material-symbols-outlined">close</span>
        Inchide
      </button>
      <nav className="flex flex-col space-y-6">
        {navLinks.map((link) => (
          <Link className="font-display text-5xl font-bold text-white transition-all duration-300 hover:text-[#8FABD4] md:text-7xl" href={link.href} key={link.label} onClick={onClose}>
            {link.label}
          </Link>
        ))}
      </nav>
    </div>
  );
}

function Footer() {
  return (
    <footer className="w-full bg-black px-5 py-24 md:px-20 md:py-32">
      <div className="mb-12 flex flex-col items-start justify-between gap-10 border-b border-white/10 pb-12 lg:flex-row lg:items-end">
        <h2 className="max-w-4xl font-display text-5xl font-extrabold uppercase leading-none text-white md:text-[96px]">Gata sa imparti?</h2>
        <Link className="bg-[#4A70A9] px-12 py-6 font-mono text-xs uppercase tracking-widest text-white transition-colors duration-300 hover:bg-white hover:text-[#30578F]" href="/download">
          Incepe acum
        </Link>
      </div>
      <div className="grid grid-cols-1 gap-8 md:grid-cols-3">
        <FooterColumn title="Navigare">
          <Link href="/">Acasa</Link>
          <Link href="/features">Functionalitati</Link>
          <Link href="/community">Povesti</Link>
          <Link href="/archive">Arhiva</Link>
        </FooterColumn>
        <FooterColumn title="Legal">
          <Link href="/privacy-policy">Confidentialitate</Link>
          <Link href="/terms-and-conditions">Termeni</Link>
          <Link href="/cookie-policy">Cookies</Link>
          <Link href="/account-deletion">Stergere cont</Link>
        </FooterColumn>
        <FooterColumn title="Contact">
          <a href="mailto:support@borrowit.app">support@borrowit.app</a>
          <Link href="/support">Suport</Link>
        </FooterColumn>
      </div>
    </footer>
  );
}

function FooterColumn({ title, children }) {
  return (
    <div className="flex flex-col gap-6">
      <p className="font-mono text-xs uppercase tracking-widest text-white/60">{title}</p>
      <div className="flex flex-col gap-2 text-xl leading-8 text-white">{children}</div>
    </div>
  );
}
