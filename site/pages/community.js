/* eslint-disable @next/next/no-img-element */
import Head from "next/head";
import Link from "next/link";
import { useEffect, useMemo, useState } from "react";

const images = {
  hero:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuAoeiXJs5zk4XUXyJAzlx_4Lo6MY9v927n1Y6iVPnzO1-DSsDKOcK4iHdGdZnoa2ufnsTJAjgpb-VTERqQnmHZ4GNlBurj2hg5WtXCUkkyzh2ciICbbjBSAMWelmsUww5te0zi836tTHWLkchmQlsB7WY2Ym-bgri1vCdeZEXIeg0_pNxZwMHjIjvNSjF0TVIY6eORWrnMjPHmruugpY-WORqb9j-lTHa5xGw8ZNy27eqt2PamHIQ1gzmaQrElVPgbo2C5PWn15LBk",
  cello:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuBry271nKvJkTTW-1zpvs4MWGHSMMgyPyfsK1MPk5phSayFeQEd48tYoCeUFg2yi88Np1WYK5aMUpHMIdL-tjKgh2oPi7a_eJ4gn3EccekiUZvgdpGXhVv9ncQJBlX26pP67Y4kWbxh_ldJlwFI1i702j5FmtGE1czEVoFjBRbBW0pw8OmQ9f9B0UY7r_pTmaaRdHGR60nyZX-bd2nJvgLIG_vI-s2P1F9dqdAnmC1BwRv-5d_18yQYmQ8OGHmoXaGp0erXMo-8pp0",
  closet:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuBGTZttzy9KI7nX_s-e4u_mIugdN88ASChzp-lGofFtvn_SpNlO72andd3dm7O67CbSYy76NYev6PcpKpK4wMcKNysa1xo7AqY7tnanwNreE-kiYLRxsPKrDRDhcovFnvFaBWkUDCNBsdYgtTrZPHLvKQ_ImGKOp3hRsG_iAlU4z-wjHZakgCQtXlLssq17Mf4Ve_Uy0YL3pl_8ikLm-IuYTUawJcsLXrtfphxo-Im1VdhuWKAmXR-078VF_KcSJPF_8oCdH3P6RE4",
};

const points = [
  [74, 86], [166, 188], [244, 124], [302, 290], [388, 206], [466, 342],
  [540, 142], [622, 260], [704, 100], [792, 334], [874, 196], [936, 390],
  [120, 350], [214, 410], [348, 426], [616, 426], [738, 454], [910, 74],
  [56, 250], [138, 52], [274, 454], [424, 88], [508, 238], [582, 70],
  [656, 372], [724, 214], [822, 456], [966, 270], [36, 422], [190, 286],
  [328, 58], [454, 454], [570, 302], [676, 48], [760, 146], [846, 304],
  [944, 126], [102, 442], [252, 222], [502, 42],
];

const connections = [
  [0, 1], [1, 2], [2, 4], [3, 4], [4, 5], [4, 6], [6, 7], [7, 8],
  [7, 9], [8, 10], [10, 11], [12, 13], [13, 14], [5, 15], [15, 16],
  [10, 17], [2, 12], [9, 16], [6, 10], [18, 1], [19, 0], [20, 14],
  [21, 4], [22, 7], [23, 6], [24, 15], [25, 34], [26, 35], [27, 11],
  [28, 37], [29, 38], [30, 2], [31, 15], [32, 22], [33, 23], [34, 8],
  [35, 27], [36, 17], [38, 3], [39, 6],
];

const testimonials = [
  {
    className: "left-[5%] top-[10%] bg-white text-black",
    quote: "Cel mai simplu mod de a folosi lucruri bune fara sa le aduni prin casa.",
    author: "Sara K.",
    speed: 2,
  },
  {
    className: "right-[10%] top-[40%] max-w-sm bg-black p-10 text-white",
    quote: "Am cunoscut oameni foarte buni pornind de la un schimb simplu de scule.",
    author: "Marius T.",
    speed: 4,
  },
  {
    className: "bottom-[15%] left-[20%] bg-white text-black",
    quote: "Increderea e greu de construit, dar BorrowIt face procesul clar.",
    author: "Elena R.",
    speed: 1.5,
  },
];

export default function Community() {
  const [menuOpen, setMenuOpen] = useState(false);
  const [progress, setProgress] = useState(0);
  const [parallax, setParallax] = useState(0);

  useEffect(() => {
    const revealObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) entry.target.classList.add("reveal-active");
        });
      },
      { threshold: 0.2 },
    );

    document.querySelectorAll(".community-reveal").forEach((item) => revealObserver.observe(item));

    const handleScroll = () => {
      const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
      setProgress(maxScroll > 0 ? window.scrollY / maxScroll : 0);
      setParallax(window.scrollY);
    };

    window.addEventListener("scroll", handleScroll, { passive: true });
    handleScroll();

    return () => {
      revealObserver.disconnect();
      window.removeEventListener("scroll", handleScroll);
    };
  }, []);

  const mapLines = useMemo(
    () => connections.map(([from, to]) => ({ from: points[from], to: points[to] })),
    [],
  );

  return (
    <>
      <Head>
        <title>Comunitate BorrowIt | Povesti reale din economia de sharing</title>
        <meta
          name="description"
          content="Descopera comunitatea BorrowIt: povesti despre oameni, obiecte verificate si incredere construita prin inchirieri locale."
        />
      </Head>

      <div
        className="fixed left-0 top-0 z-[70] h-0.5 w-full origin-left bg-[#4A70A9] transition-transform"
        style={{ transform: `scaleX(${progress})` }}
      />

      <MegaMenu open={menuOpen} onClose={() => setMenuOpen(false)} />
      <Header onMenu={() => setMenuOpen(true)} />

      <main className="w-full overflow-hidden bg-[#f9f9f9] pt-20">
        <section className="relative flex flex-col items-end gap-8 px-5 py-24 md:px-20 md:py-40 lg:flex-row">
          <div className="relative z-10 lg:w-7/12">
            <span className="mb-8 block font-mono text-xs uppercase tracking-[0.2em] text-[#444748]/70">
              Vocile comunitatii
            </span>
            <h1 className="community-display-2xl mb-12 font-display font-extrabold text-black">
              Arhiva <br />
              <span className="italic text-[#444748]">experientelor</span>
              <br />
              impartite.
            </h1>
            <p className="max-w-xl text-xl leading-8 text-[#444748]">
              BorrowIt este mai mult decat o platforma. Este o comunitate de oameni care aleg accesul inteligent in locul proprietatii inutile.
            </p>
          </div>
          <div className="community-reveal group relative overflow-hidden lg:w-5/12">
            <img
              className="reveal-image h-[420px] w-full object-cover grayscale transition-all duration-700 ease-in-out hover:grayscale-0 md:h-[600px]"
              src={images.hero}
              alt="Membri ai comunitatii BorrowIt impartind o camera foto"
            />
            <div className="absolute bottom-0 left-0 bg-black p-6 font-mono text-xs uppercase tracking-widest text-white md:p-8">
              Poveste: colectivul creatorilor
            </div>
          </div>
        </section>

        <section className="relative w-full overflow-hidden bg-black px-5 py-24 text-white md:px-20 md:py-40">
          <div className="mb-20 flex flex-col items-start justify-between gap-10 lg:flex-row">
            <div className="max-w-2xl">
              <h2 className="community-display-lg mb-6 font-display font-bold">
                Pulsul retelei
              </h2>
              <p className="text-base leading-6 text-white/70">
                Schimburi reale intre oameni. Fiecare nod inseamna un obiect folosit mai bine, o resursa salvata si o conexiune noua.
              </p>
            </div>
            <div className="flex gap-12">
              <NetworkStat value="12.4k" label="Noduri active" />
              <NetworkStat value="89%" label="Incredere repetata" />
            </div>
          </div>

          <div className="group relative flex h-[360px] w-full cursor-crosshair items-center justify-center border border-white/10 md:h-[500px]">
            <svg className="h-full w-full opacity-40" fill="none" viewBox="0 0 1000 500" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <filter id="community-glow">
                  <feGaussianBlur result="coloredBlur" stdDeviation="2.5" />
                  <feMerge>
                    <feMergeNode in="coloredBlur" />
                    <feMergeNode in="SourceGraphic" />
                  </feMerge>
                </filter>
              </defs>
              <g>
                {mapLines.map((line, index) => (
                  <line
                    key={`${line.from[0]}-${line.to[0]}-${index}`}
                    x1={line.from[0]}
                    y1={line.from[1]}
                    x2={line.to[0]}
                    y2={line.to[1]}
                    stroke="white"
                    strokeDasharray="1000"
                    strokeDashoffset="0"
                    strokeWidth="0.5"
                    opacity="0.2"
                  />
                ))}
                {points.map(([x, y], index) => (
                  <circle
                    className="transition-all duration-500 hover:fill-white"
                    cx={x}
                    cy={y}
                    fill="#8FABD4"
                    filter={index % 5 === 0 ? "url(#community-glow)" : undefined}
                    key={`${x}-${y}`}
                    r={index % 5 === 0 ? 5 : 2}
                  />
                ))}
              </g>
            </svg>
            <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
              <div className="text-center transition-transform duration-500 group-hover:scale-110">
                <span className="mb-2 block font-mono text-xs uppercase tracking-widest">Retea live</span>
                <div className="mx-auto h-px w-24 bg-[#8FABD4]" />
              </div>
            </div>
          </div>
        </section>

        <section className="space-y-32 px-5 py-24 md:px-20 md:py-40">
          <Story
            image={images.cello}
            label="Schimb muzical"
            title="Andrei si violoncelul de secol XVIII"
            text="Aveam nevoie de un instrument profesional pentru o sesiune de inregistrare aparuta pe ultima suta de metri. Prin BorrowIt am gasit rapid un proprietar verificat si un obiect documentat corect."
            cta="Citeste povestea"
          />
          <Story
            image={images.closet}
            label="Stil sustenabil"
            title="Dulapul care circula prin oras"
            text="Aveam haine bune pe care nu le purtam aproape niciodata. Acum sunt folosite de alti oameni, iar eu castig bani fara sa cumpar si mai multe lucruri."
            cta="Exploreaza arhiva"
            inverse
          />
        </section>

        <section className="relative flex h-[800px] w-full items-center justify-center overflow-hidden bg-[#eeeeee]">
          <div className="pointer-events-none absolute inset-0 opacity-10">
            <h2 className="select-none whitespace-nowrap font-display text-[20vw] font-extrabold uppercase text-black">
              Comunitatea pe primul loc Comunitatea pe primul loc
            </h2>
          </div>
          <div className="relative h-full w-full max-w-[1440px]">
            {testimonials.map((item) => (
              <div
                className={`absolute max-w-xs shadow-sm ${item.className.includes("p-10") ? "" : "p-8"} ${item.className}`}
                key={item.author}
                style={{ transform: `translateY(${-parallax * item.speed / 28}px)` }}
              >
                <p className="mb-4 text-base italic leading-6">{item.quote}</p>
                <span className="font-mono text-xs uppercase tracking-widest">- {item.author}</span>
              </div>
            ))}
            <div
              className="absolute bottom-[25%] right-[24%] max-w-[220px] bg-[#30578F] p-6 text-white"
              style={{ transform: `translateY(${-parallax * 3 / 28}px)` }}
            >
              <p className="font-mono text-sm font-bold uppercase leading-5">
                1.200 kg de risipa evitata luna aceasta.
              </p>
            </div>
          </div>
        </section>

        <section className="bg-[#f9f9f9] px-5 py-24 text-center md:px-20 md:py-40">
          <div className="mx-auto max-w-3xl">
            <h2 className="community-display-lg mb-8 font-display font-bold text-black">
              Scrie propriul <span className="text-[#4A70A9]">capitol.</span>
            </h2>
            <p className="mb-12 text-xl leading-8 text-[#444748]">
              Pune un obiect la inchiriat sau rezerva ceva de care ai nevoie. Intra in economia circulara cu pasi simpli si verificati.
            </p>
            <div className="flex flex-col justify-center gap-4 sm:flex-row">
              <Link
                className="bg-black px-10 py-5 font-mono text-xs uppercase tracking-widest text-white transition-colors hover:bg-[#30578F]"
                href="/download"
              >
                Adauga un obiect
              </Link>
              <Link
                className="border border-black px-10 py-5 font-mono text-xs uppercase tracking-widest text-black transition-colors hover:bg-black hover:text-white"
                href="/archive"
              >
                Vezi arhiva
              </Link>
            </div>
          </div>
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
          <Link className="font-mono text-xs uppercase tracking-widest text-black" href="/community">
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
            className={`font-display text-5xl font-bold transition-all duration-300 md:text-7xl ${link.href === "/community" ? "text-[#8FABD4]" : "text-white hover:text-[#8FABD4]"}`}
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

function NetworkStat({ value, label }) {
  return (
    <div>
      <span className="block font-display text-[48px] font-bold leading-none">{value}</span>
      <span className="font-mono text-xs uppercase tracking-widest text-white/50">{label}</span>
    </div>
  );
}

function Story({ image, label, title, text, cta, inverse = false }) {
  return (
    <div className="grid grid-cols-12 items-center gap-8">
      <div className={`community-reveal col-span-12 lg:col-span-6 ${inverse ? "order-1 lg:col-start-7 lg:order-2" : ""}`}>
        <div className="relative">
          <img
            className={`reveal-image w-full object-cover ${inverse ? "h-[460px] md:h-[600px]" : "h-[460px] md:h-[700px]"}`}
            src={image}
            alt={title}
          />
          {inverse ? (
            <div className="absolute -right-12 -top-12 hidden h-48 w-48 rotate-12 items-center justify-center bg-[#e2e2e2] p-8 text-center lg:flex">
              <span className="font-mono text-[10px] uppercase leading-tight text-black">
                Membru verificat din comunitate din 2021
              </span>
            </div>
          ) : null}
        </div>
      </div>
      <div className={`col-span-12 lg:col-span-4 ${inverse ? "order-2 lg:order-1 lg:col-start-2" : "lg:col-start-8"}`}>
        <span className="mb-4 block font-mono text-xs uppercase tracking-widest text-[#4A70A9]">{label}</span>
        <h3 className="mb-6 text-[32px] font-medium leading-10 tracking-normal text-black">{title}</h3>
        <p className="mb-8 text-base leading-6 text-[#444748]">{text}</p>
        <Link className="inline-flex items-center gap-4 border-b border-black pb-2 font-mono text-xs uppercase tracking-widest text-black transition-all hover:gap-8" href={inverse ? "/archive" : "/community"}>
          {cta}
        </Link>
      </div>
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
