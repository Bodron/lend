import Head from "next/head";
import Link from "next/link";
import { useEffect, useLayoutEffect, useRef, useState } from "react";

const featureCards = [
  {
    eyebrow: "Protocol / 01",
    title: ["Partajare", "sigura"],
    text: "Fiecare obiect este protejat prin verificari, garantie si documentare digitala. Predarea si returul sunt clare, iar obiectele valoroase raman in stare buna de la o inchiriere la alta.",
    icon: "verified_user",
    note: "Custodie verificata",
    visual: "orbit",
  },
  {
    eyebrow: "Mecanic / 02",
    title: ["Rezervare", "instant"],
    text: "Motorul de disponibilitate iti arata rapid perioada libera, costul total si garantia. Rezervi obiectul fara frictiune, direct din aplicatie.",
    icon: "bolt",
    note: "UX rapid",
    visual: "pulse",
  },
  {
    eyebrow: "Ecosistem / 03",
    title: ["Incredere", "in comunitate"],
    text: "Profilurile verificate, ratingurile si istoricul inchirierilor construiesc reputatie reala intre proprietari si chiriasi.",
    icon: "groups",
    note: "Identitate verificata",
    visual: "grid",
  },
];

const stats = [
  {
    label: "Valoare tranzactii",
    target: 420,
    suffix: "M",
    text: "RON administrati anual prin infrastructura noastra de rezervari, garantii si contracte digitale.",
  },
  {
    label: "Rating incredere",
    target: 4.9,
    suffix: "",
    text: "Media ratingului pentru membrii verificati care folosesc BorrowIt.",
  },
  {
    label: "Inventar activ",
    target: 15,
    suffix: "K+",
    text: "Obiecte curate si verificate, disponibile pentru inchiriere locala.",
  },
];

const specs = [
  {
    number: "01",
    title: "Garantii pentru proprietari",
    text: "Acoperire pentru obiecte valoroase, depozite clare si documentare la predare si retur.",
  },
  {
    number: "02",
    title: "Contracte digitale",
    text: "Acorduri de inchiriere generate automat, cu confirmari pentru garantie, perioada si retur.",
  },
  {
    number: "03",
    title: "Predare asistata",
    text: "Fluxuri simple pentru obiecte importante: poze, stare obiect, locatie si confirmare de la ambele parti.",
  },
  {
    number: "04",
    title: "Preturi dinamice",
    text: "Recomandari de pret in functie de categorie, cerere, durata si valoarea obiectului.",
  },
];

export default function FeaturesPage() {
  const [menuOpen, setMenuOpen] = useState(false);
  const [progress, setProgress] = useState(0);
  const [horizontalHeight, setHorizontalHeight] = useState("180vh");
  const [counts, setCounts] = useState(["0", "0", "0"]);
  const horizontalSectionRef = useRef(null);
  const horizontalViewportRef = useRef(null);
  const railRef = useRef(null);
  const statsRef = useRef(null);
  const countedRef = useRef(false);
  const maxHorizontalTravelRef = useRef(0);

  const updateHorizontalPosition = () => {
    const section = horizontalSectionRef.current;
    const rail = railRef.current;
    if (!section || !rail || window.innerWidth < 1024) return;

    const viewport = horizontalViewportRef.current;
    const stickyHeight = viewport?.clientHeight ?? window.innerHeight;
    const stickyOffset = 80;
    const sectionStart = section.offsetTop - stickyOffset;
    const scrollableDistance = Math.max(1, section.offsetHeight - stickyHeight);
    const sectionProgress = Math.max(
      0,
      Math.min(1, (window.scrollY - sectionStart) / scrollableDistance),
    );
    rail.style.transform = `translate3d(-${sectionProgress * maxHorizontalTravelRef.current}px, 0, 0)`;
  };

  useLayoutEffect(() => {
    const measureHorizontal = () => {
      const viewport = horizontalViewportRef.current;
      const rail = railRef.current;
      if (!viewport || !rail) return;

      if (window.innerWidth < 1024) {
        maxHorizontalTravelRef.current = 0;
        setHorizontalHeight("auto");
        rail.style.transform = "translate3d(0, 0, 0)";
        return;
      }

      rail.style.transform = "translate3d(0, 0, 0)";
      const cards = rail.querySelectorAll("[data-feature-card]");
      const lastCard = cards[cards.length - 1];
      if (!lastCard) return;

      const viewportRect = viewport.getBoundingClientRect();
      const lastCardRect = lastCard.getBoundingClientRect();
      const maxTravel = Math.max(0, lastCardRect.right - viewportRect.right + 80);
      maxHorizontalTravelRef.current = maxTravel;
      setHorizontalHeight(`${viewport.clientHeight + maxTravel}px`);
      requestAnimationFrame(updateHorizontalPosition);
    };

    measureHorizontal();
    window.addEventListener("resize", measureHorizontal);
    document.fonts?.ready?.then(measureHorizontal);

    return () => window.removeEventListener("resize", measureHorizontal);
  }, []);

  useEffect(() => {
    const handleScroll = () => {
      const maxPageScroll = document.documentElement.scrollHeight - window.innerHeight;
      setProgress(maxPageScroll > 0 ? window.scrollY / maxPageScroll : 0);
      updateHorizontalPosition();
    };

    const observer = new IntersectionObserver(
      (entries) => {
        if (!entries[0].isIntersecting || countedRef.current) return;
        countedRef.current = true;
        const startedAt = performance.now();
        const duration = 2000;

        const tick = (now) => {
          const ratio = Math.min((now - startedAt) / duration, 1);
          setCounts(
            stats.map((stat) => {
              const value = stat.target * ratio;
              return stat.target % 1 === 0 ? `${Math.floor(value)}${stat.suffix}` : `${value.toFixed(1)}${stat.suffix}`;
            }),
          );
          if (ratio < 1) requestAnimationFrame(tick);
        };

        requestAnimationFrame(tick);
      },
      { threshold: 0.25 },
    );

    if (statsRef.current) observer.observe(statsRef.current);
    window.addEventListener("scroll", handleScroll, { passive: true });
    handleScroll();

    return () => {
      observer.disconnect();
      window.removeEventListener("scroll", handleScroll);
    };
  }, []);

  return (
    <>
      <Head>
        <title>Functionalitati BorrowIt | Siguranta, rezervari si incredere</title>
        <meta
          name="description"
          content="Descopera functionalitatile BorrowIt: verificare, garantii, contracte digitale, rezervari rapide si reputatie in comunitate."
        />
      </Head>

      <div
        className="fixed left-0 top-0 z-[70] h-0.5 w-full origin-left bg-[#4A70A9] transition-transform"
        style={{ transform: `scaleX(${progress})` }}
      />

      <MegaMenu open={menuOpen} onClose={() => setMenuOpen(false)} />
      <Header onMenu={() => setMenuOpen(true)} />

      <main className="w-full [overflow-x:clip] bg-[#f9f9f9] pt-20">
        <section className="relative flex w-full flex-col items-start overflow-hidden px-5 py-24 md:px-20 md:py-40">
          <GridTexture />
          <span className="mb-8 flex items-center gap-4 font-mono text-xs uppercase tracking-[0.3em] text-black">
            <span className="h-px w-12 bg-black" />
            Mecanica increderii
          </span>
          <h1 className="download-display-2xl relative z-10 mb-12 max-w-5xl font-display font-extrabold text-black">
            Un protocol pentru <br />
            <span className="italic text-[#444748]">inchiriere fara frictiune.</span>
          </h1>
          <div className="flex w-full justify-end">
            <p className="max-w-xl text-xl leading-8 text-[#444748]">
              Am reconstruit felul in care oamenii imprumuta obiecte. De la verificarea identitatii pana la rezervari rapide si contracte digitale, BorrowIt este gandit pentru acces sigur fara proprietate inutila.
            </p>
          </div>
        </section>

        <section className="relative bg-black" ref={horizontalSectionRef} style={{ height: horizontalHeight }}>
          <div
            className="features-horizontal flex min-h-screen w-full snap-x snap-mandatory items-center gap-8 overflow-x-auto px-5 py-24 text-white md:px-20 md:py-32 lg:sticky lg:top-20 lg:h-[calc(100vh-80px)] lg:min-h-0 lg:snap-none lg:overflow-hidden lg:py-0"
            ref={horizontalViewportRef}
          >
            <div className="flex items-center gap-8 will-change-transform" ref={railRef}>
              {featureCards.map((feature) => (
                <FeatureCard feature={feature} key={feature.eyebrow} />
              ))}
              <div className="w-5 shrink-0 md:w-20" />
            </div>
          </div>
        </section>

        <section className="w-full bg-[#f9f9f9] px-5 py-24 md:px-20 md:py-40" ref={statsRef}>
          <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
            {stats.map((stat, index) => (
              <div className="flex flex-col gap-4" key={stat.label}>
                <span className="font-mono text-xs uppercase tracking-widest text-black/40">{stat.label}</span>
                <span className="community-display-lg font-display font-bold text-black">{counts[index]}</span>
                <p className="text-base leading-6 text-[#444748]">{stat.text}</p>
              </div>
            ))}
          </div>
        </section>

        <section className="w-full bg-[#eeeeee] px-5 py-24 md:px-20 md:py-40">
          <div className="mb-20">
            <h3 className="mb-4 text-[32px] font-medium uppercase leading-10 tracking-widest text-black">
              Specificatii principale
            </h3>
            <div className="h-1 w-32 bg-black" />
          </div>
          <div className="grid grid-cols-1 gap-x-24 gap-y-16 md:grid-cols-2">
            {specs.map((spec) => (
              <article
                className="group cursor-default border-b border-black/10 pb-8 transition-colors hover:border-black"
                key={spec.number}
              >
                <div className="mb-4 flex items-start justify-between">
                  <span className="font-mono text-xs uppercase tracking-widest text-black/30">{spec.number}</span>
                  <span className="material-symbols-outlined text-black/20 transition-colors group-hover:text-black">
                    arrow_outward
                  </span>
                </div>
                <h4 className="mb-4 font-display text-[32px] font-bold leading-10 text-black">{spec.title}</h4>
                <p className="text-base leading-6 text-[#444748]">{spec.text}</p>
              </article>
            ))}
          </div>
        </section>
      </main>

      <Footer />
    </>
  );
}

function GridTexture() {
  return (
    <div className="pointer-events-none absolute right-0 top-0 h-full w-1/2 opacity-10">
      <div className="h-full w-full [mask-image:radial-gradient(circle_at_center,white,transparent)]">
        <div className="grid h-full w-full grid-cols-12">
          {Array.from({ length: 12 }).map((_, index) => (
            <div className="h-full border-l border-black" key={index} />
          ))}
        </div>
      </div>
    </div>
  );
}

function FeatureCard({ feature }) {
  return (
    <article data-feature-card className="relative flex h-[620px] w-[82vw] shrink-0 snap-center overflow-hidden bg-white/[0.05] md:h-[716px] lg:w-[60vw]">
      <div className="absolute left-0 top-0 flex h-full w-16 items-center justify-center border-r border-white/10">
        <span className="rotate-180 font-mono text-xs uppercase tracking-[0.5em] text-white/40 [writing-mode:vertical-rl]">
          {feature.eyebrow}
        </span>
      </div>
      <div className="ml-16 flex h-full w-full flex-col lg:flex-row">
        <div className="flex flex-1 flex-col justify-between p-8 md:p-12">
          <div>
            <h2 className="community-display-lg mb-6 font-display font-bold text-white">
              {feature.title[0]} <br />
              {feature.title[1]}
            </h2>
            <p className="max-w-md text-xl leading-8 text-white/60">{feature.text}</p>
          </div>
          <div className="flex items-center gap-6">
            <div className="flex h-16 w-16 items-center justify-center rounded-full border border-white/20">
              <span className="material-symbols-outlined text-[32px]">{feature.icon}</span>
            </div>
            <span className="font-mono text-xs uppercase tracking-widest">{feature.note}</span>
          </div>
        </div>
        <div className="relative flex-1 bg-white/10">
          <FeatureVisual type={feature.visual} />
        </div>
      </div>
    </article>
  );
}

function FeatureVisual({ type }) {
  if (type === "orbit") {
    return (
      <div className="absolute inset-0 flex items-center justify-center overflow-hidden">
        <svg className="h-full w-full opacity-25" viewBox="0 0 100 100">
          <defs>
            <linearGradient id="feature-grad" x1="0%" x2="100%" y1="0%" y2="100%">
              <stop offset="0%" stopColor="#8FABD4" stopOpacity="1" />
              <stop offset="100%" stopColor="transparent" stopOpacity="0" />
            </linearGradient>
          </defs>
          <circle cx="50" cy="50" fill="none" r="30" stroke="url(#feature-grad)" strokeWidth="0.5" />
          <path d="M20,50 Q50,20 80,50 T20,50" fill="none" opacity="0.5" stroke="white" strokeWidth="0.1" />
        </svg>
      </div>
    );
  }

  if (type === "pulse") {
    return (
      <div className="absolute inset-0 flex items-center justify-center">
        <div className="flex h-48 w-48 animate-pulse items-center justify-center rounded-full border border-white/10">
          <div className="flex h-32 w-32 items-center justify-center rounded-full border border-white/20">
            <div className="h-16 w-16 rounded-full bg-[#4A70A9] opacity-30 blur-2xl" />
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="absolute inset-0 flex items-center justify-center">
      <div className="grid grid-cols-4 gap-4 p-8 opacity-40">
        {Array.from({ length: 8 }).map((_, index) => (
          <div className={`aspect-square rounded-full ${index % 2 === 0 ? "bg-white/20" : "bg-white/5"}`} key={index} />
        ))}
      </div>
      <div className="absolute inset-0 bg-gradient-to-t from-black to-transparent" />
    </div>
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
  const links = [
    { label: "Acasa", href: "/" },
    { label: "Functionalitati", href: "/features" },
    { label: "Comunitate", href: "/community" },
    { label: "Arhiva", href: "/archive" },
    { label: "Descarca", href: "/download" },
  ];

  return (
    <div className={`mega-menu-overlay fixed inset-0 z-[60] flex flex-col justify-center bg-black px-5 md:px-20 ${open ? "mega-menu-open" : ""}`} aria-hidden={!open}>
      <button className="absolute right-6 top-8 flex items-center gap-2 font-mono text-xs uppercase tracking-widest text-white md:right-10 md:top-10" onClick={onClose} type="button">
        <span className="material-symbols-outlined">close</span>
        Inchide
      </button>
      <nav className="flex flex-col space-y-6">
        {links.map((link) => (
          <Link
            className={`font-display text-5xl font-bold transition-all duration-300 md:text-7xl ${link.href === "/features" ? "text-[#8FABD4]" : "text-white hover:text-[#8FABD4]"}`}
            href={link.href}
            key={link.label}
            onClick={onClose}
          >
            {link.label}
          </Link>
        ))}
      </nav>
    </div>
  );
}

function Footer() {
  return (
    <footer className="w-full bg-black px-5 py-32 md:px-20 md:py-40">
      <div className="mb-12 flex flex-col items-start justify-between gap-10 border-b border-white/10 pb-12 lg:flex-row lg:items-end">
        <h2 className="max-w-4xl font-display text-6xl font-extrabold uppercase leading-none text-white md:text-[120px]">Gata sa imparti?</h2>
        <Link className="bg-[#4A70A9] px-12 py-6 font-mono text-xs uppercase tracking-widest text-white transition-colors duration-300 hover:bg-white hover:text-[#30578F]" href="/download">
          Incepe acum
        </Link>
      </div>
      <div className="mb-20 grid grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-4">
        <FooterColumn title="Social">
          <a href="#">Instagram</a>
          <a href="#">Twitter/X</a>
          <a href="#">LinkedIn</a>
        </FooterColumn>
        <FooterColumn title="Navigare">
          <Link href="/">Acasa</Link>
          <Link href="/features">Functionalitati</Link>
          <Link href="/community">Povesti</Link>
          <Link href="/archive">Arhiva</Link>
        </FooterColumn>
        <div className="flex flex-col gap-6 md:col-span-2">
          <p className="font-mono text-xs uppercase tracking-widest text-white/60">Newsletter</p>
          <form className="relative flex w-full items-center border-b border-white/20">
            <input className="w-full bg-transparent py-4 text-xl leading-8 text-white outline-none placeholder:text-white/35" placeholder="Introdu adresa de email" type="email" />
            <button className="material-symbols-outlined text-white" type="submit">arrow_forward</button>
          </form>
        </div>
      </div>
      <div className="flex flex-col justify-between gap-8 border-t border-white/5 pt-8 md:flex-row">
        <span className="font-mono text-xs uppercase tracking-widest text-white/40">© 2026 BorrowIt. Construit pentru economia de sharing.</span>
        <div className="flex flex-wrap gap-6">
          <Link className="font-mono text-xs uppercase tracking-widest text-white/40" href="/privacy-policy">Confidentialitate</Link>
          <Link className="font-mono text-xs uppercase tracking-widest text-white/40" href="/terms-and-conditions">Termeni</Link>
          <Link className="font-mono text-xs uppercase tracking-widest text-white/40" href="/support">Suport</Link>
        </div>
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
