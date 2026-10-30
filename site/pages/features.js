import Head from "next/head";
import Link from "next/link";
import PublicHeader from "../components/PublicHeader";
import PublicFooter from "../components/PublicFooter";
import { useRouter } from "next/router";
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
    text: "Media ratingului pentru membrii verificati care folosesc PINLEND.",
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

const englishFeatures = [
  { eyebrow: "Protocol / 01", title: ["Safe", "sharing"], text: "Every item is protected by checks, deposits, and digital records. Handover and return are clear, so valuable items stay in good condition.", note: "Verified handover" },
  { eyebrow: "Mechanics / 02", title: ["Instant", "booking"], text: "See available dates, the total price, and the deposit at a glance. Book directly in the app.", note: "Fast booking" },
  { eyebrow: "Community / 03", title: ["Trust in", "the community"], text: "Verified profiles, ratings, and rental history build a real reputation between owners and renters.", note: "Verified identity" },
];
const englishStats = [
  { label: "Transaction value", text: "RON processed annually through our booking, deposit, and digital contract services." },
  { label: "Trust rating", text: "Average rating for verified members using PINLEND." },
  { label: "Active inventory", text: "Clean, verified items available for local rental." },
];
const englishSpecs = [
  { title: "Protection for owners", text: "Coverage for valuable items, clear deposits, and records at handover and return." },
  { title: "Digital contracts", text: "Rental agreements created automatically, with confirmations for the deposit, period, and return." },
  { title: "Guided handover", text: "Simple steps for important items: photos, condition, location, and confirmation from both sides." },
  { title: "Dynamic pricing", text: "Price suggestions based on category, demand, duration, and item value." },
];

export default function FeaturesPage() {
  const en = useRouter().locale === "en";
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
        <title>{en ? "PINLEND features | Safe sharing and quick bookings" : "Functionalitati PINLEND | Siguranta, rezervari si incredere"}</title>
        <meta
          name="description"
          content={en ? "Explore PINLEND features: verification, deposits, digital contracts, quick bookings, and community trust." : "Descopera functionalitatile PINLEND: verificare, garantii, contracte digitale, rezervari rapide si reputatie in comunitate."}
        />
      </Head>

      <PublicHeader current="/features" />

      <main className="w-full [overflow-x:clip] bg-[#f9f9f9] pt-20">
        <section className="relative flex w-full flex-col items-start overflow-hidden px-5 py-24 md:px-20 md:py-40">
          <GridTexture />
          <span className="mb-8 flex items-center gap-4 font-mono text-xs uppercase tracking-[0.3em] text-black">
            <span className="h-px w-12 bg-black" />
            {en ? "How trust works" : "Mecanica increderii"}
          </span>
          <h1 className="download-display-2xl relative z-10 mb-12 max-w-5xl font-display font-extrabold text-black">
            {en ? "A better way to" : "Un protocol pentru"} <br />
            <span className="italic text-[#444748]">{en ? "rent with confidence." : "inchiriere fara frictiune."}</span>
          </h1>
          <div className="flex w-full justify-end">
            <p className="max-w-xl text-xl leading-8 text-[#444748]">
              {en ? "We have made it easier to share useful things. From identity verification to quick bookings and digital contracts, PINLEND gives you safe access without unnecessary ownership." : "Am reconstruit felul in care oamenii imprumuta obiecte. De la verificarea identitatii pana la rezervari rapide si contracte digitale, PINLEND este gandit pentru acces sigur fara proprietate inutila."}
            </p>
          </div>
        </section>

        <section className="relative bg-black" ref={horizontalSectionRef} style={{ height: horizontalHeight }}>
          <div
            className="features-horizontal flex min-h-screen w-full snap-x snap-mandatory items-center gap-8 overflow-x-auto px-5 py-24 text-white md:px-20 md:py-32 lg:sticky lg:top-20 lg:h-[calc(100vh-80px)] lg:min-h-0 lg:snap-none lg:overflow-hidden lg:py-0"
            ref={horizontalViewportRef}
          >
            <div className="flex items-center gap-8 will-change-transform" ref={railRef}>
              {featureCards.map((feature, index) => (
                <FeatureCard feature={en ? { ...feature, ...englishFeatures[index] } : feature} key={feature.eyebrow} />
              ))}
              <div className="w-5 shrink-0 md:w-20" />
            </div>
          </div>
        </section>

        <section className="w-full bg-[#f9f9f9] px-5 py-24 md:px-20 md:py-40" ref={statsRef}>
          <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
            {stats.map((stat, index) => (
              <div className="flex flex-col gap-4" key={stat.label}>
                <span className="font-mono text-xs uppercase tracking-widest text-black/40">{en ? englishStats[index].label : stat.label}</span>
                <span className="community-display-lg font-display font-bold text-black">{counts[index]}</span>
                <p className="text-base leading-6 text-[#444748]">{en ? englishStats[index].text : stat.text}</p>
              </div>
            ))}
          </div>
        </section>

        <section className="w-full bg-[#eeeeee] px-5 py-24 md:px-20 md:py-40">
          <div className="mb-20">
            <h3 className="mb-4 text-[32px] font-medium uppercase leading-10 tracking-widest text-black">
              {en ? "Key features" : "Specificatii principale"}
            </h3>
            <div className="h-1 w-32 bg-black" />
          </div>
          <div className="grid grid-cols-1 gap-x-24 gap-y-16 md:grid-cols-2">
            {specs.map((spec, index) => (
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
                <h4 className="mb-4 font-display text-[32px] font-bold leading-10 text-black">{en ? englishSpecs[index].title : spec.title}</h4>
                <p className="text-base leading-6 text-[#444748]">{en ? englishSpecs[index].text : spec.text}</p>
              </article>
            ))}
          </div>
        </section>
      </main>

      <PublicFooter />
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
