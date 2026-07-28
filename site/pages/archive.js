/* eslint-disable @next/next/no-img-element */
import Head from "next/head";
import Link from "next/link";
import { useEffect, useMemo, useState } from "react";

const listingImages = {
  leica:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuBw0wILOuL5WqkJpbfO8Fx3A8FMsUlijY-_Ivcqvyd001AYs4xCi3SWo_tvgQQJpEyEo_TSLiYZVayWVK0s5oidPQifftfRqccbCYFHft8CFlB27uiXdcH4Lvl9RdUZ0SkYuUZd9YR2Y7fgN6a3JtH5QlnJt7bgMUfK04sYeftqbxTKl8_EmHhQNbRfooDoHV6zUcDigjrk_kWwMj5bWKoGeaRb0IHRiJAgMdKp7GjwvkOZ2WzHgVA4paspzss2aI09wln8OnGqG10",
  coat:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuDvlVQa4yo7uYfleJIU7Vy0HaE-m5tBD1OnDztKxRQ2bVAa1UQ77tbYfLMXGULFH6GLRM-7LW_4FiLi48A8WxBU4yCKfQ9gzfNc3F0clyEdmwK9uc71xpy5nO_b7fg8m3gnz_34LG0a206uc6WL7q1kAKr4htgsyC_w0TmnAlhhSKcGNYb9ddnMkI1IoLn0FzM1xp9NoOFokT_KpR8frM-tdA6Bnikr--_SzzkpbKfgEyB0O0qg6tVNSFksJdUMaPA-bVMcVbxVaSk",
  saw:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuAfowsv9Hmfnfb5oP1qPvWs7WX7Q4S9vu3cmdELcCvkH5ZeqT8TMN6qdOnce8Ao3ruh8dfbIRMGhEzAWVqrdMMccJehJF0p7wiTw_6ARabh3V8C5apjZ5qa0kint6CLnQxlhF53XMGt8NR8Z1Z-VvZyObhGOhSwgoXfSg5wut7TmmQ6zL_vdlcXjmJC0xd8VKjMh8zpreO6HMJZDbgnwwHFB4Ys2qcpMY6Y3ojDQ08PBcNIt2NzHxmJEeXM0rgyYMqsCN1TYCuVqSw",
  synth:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuCs2K7RzUPa7S0pJD2kqzGIFg5z38vI33RTI_HtOGOTFRjeUU_kqin8INKhZE9on2ZrzgX6Phz17aqFZA_xga9Rce7voHydUsbuBDgZbTbj0Qfi3e6ebmP6VF2WRxvZtBCkAnpyKSPKy2d6QIlLGxR6HRW2vJ7tL5fAvXQ_XTgnaTDvugDbDpGIHC0wbcAVzUeD6o0J09--oZjLLHSVGNK7sWtcm59M5LsEa1-txe7VAjkVYLWS3o5RqbO7tjUo1_hBYCDkQrh1RkA",
  boots:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuC73b-Wamopx94zzmc1TGA0pozSFGihK9ipeWy7mQtMo56-k3L9Tkwg6itn7RRObBXuj8CvHbLEZHioeriNqFRRjGt9y9BEK-t4QI8IYsROeehWj5CezXipcRuoq-MMp3r2p_1cfAJFxGz12m0mOLgN0a8ZuUapMyQLWXXnFwCrJxJfiPfmwWtt6gt9lCPOgnhSrW53iLf44UN6zHjMf4iwkZohO_8Uvr2369eshubGz3_YoMM5Dg-cbwMhA38YkLUQ7a4B5lRC1Q4",
  drone:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuCISQ7jShwxk_NB9QHps0h5_1QBI61Nc3wGQuKCNPZ7fq7sSvK-tXVuHjWL7kGOw4nq0CxfUSzAFjWCxguCz689T8fWU3fpUUiMX_TMYO_TjeEoecEV-WiPtck_eJ6EFXNZ6Uh9SAw8nhonE3P9SGkOQVLSzeQpf32lXUEDlVAWHIhLchkO-CBo6s8CxUxgj4szWn6E1c_nRWqFEirPwlgEMBGw_3a_vuSZ1eYa4o4xKBIK_9fw8On23232BIeQbO8YnzFAg92Pvsk",
  hasselblad:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuAlMPwJWDlplRN4rqS76QVG_M-4Pbm5rVe3NRwFRM9zvvQvztXo5aZzyz1rg393djxUZzebrEXEdThKqiHjU_MYFN5W7RhxPkCexeRSi6Cp_3YcF2ZZXt_SDaJjuzRnew82LqmQkru5T2KYtMWWd33t4U2cAWLQumOwLr1XvCFwiZcsVxWRSjaPckMxrXq--7GOCcyK913dzDoCyG35qu5LwyZYc18JtEVMVRxT1OAVjKIky6s6UDF6sDbkcGyTRgNM9J79hG_jsXU",
  bag:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuCCZ9NbhYqEJZaqdAGrBRsP7Sy30i5CDmUkB8MP5d09ewGjMhSV7bPDen-BIaYyn2P9CYPM_LKc2rV7V45v4MV4CkW_6wVFdH6wIKqq3AOBwsN5mZVNc4tl3hWtSFfNoyk9T-RohbPDMJ_Y0ITd4EKKos_dyY9ij0eFzhGpHngfO8xuWco8klWNAHF31Hyrh7tgxm3GCIDGtCYZ5I2JnIdxunhAcTw9qtXRwISc-mncGyAbcIGMS5JoZlZwpWEp0Q6uIph0fvCxF6A",
};

const categories = [
  { id: "all", label: "Toate obiectele" },
  { id: "electronics", label: "Electronice" },
  { id: "tools", label: "Scule pro" },
  { id: "fashion", label: "Moda premium" },
];

const listings = [
  {
    title: "Leica M11 Black",
    price: "390 RON / zi",
    category: "electronics",
    image: listingImages.leica,
    aspect: "aspect-[4/5]",
    offset: "",
    action: "Vezi detalii",
    text: "Aparat rangefinder profesional pentru fotografie de strada si proiecte editoriale.",
  },
  {
    title: "Geaca puffer arhiva",
    price: "550 RON / zi",
    category: "fashion",
    image: listingImages.coat,
    aspect: "aspect-[3/4]",
    offset: "md:mt-12",
    action: "Inchiriaza acum",
    text: "Piesa rara din colectia 2014, cu volum sculptural si umplutura premium.",
  },
  {
    title: "Festool Kapex",
    price: "210 RON / zi",
    category: "tools",
    image: listingImages.saw,
    aspect: "aspect-square",
    offset: "",
    action: "Verifica disponibil",
    text: "Fierastrau circular profesional pentru taieturi precise in atelier sau pe santier.",
  },
  {
    title: "OP-1 Field",
    price: "230 RON / zi",
    category: "electronics",
    image: listingImages.synth,
    aspect: "aspect-[4/5]",
    offset: "lg:-mt-20",
    action: "Rezerva",
    text: "Sintetizator si sequencer portabil pentru creatori, studio si live sessions.",
  },
  {
    title: "Margiela Tabi",
    price: "300 RON / zi",
    category: "fashion",
    image: listingImages.boots,
    aspect: "aspect-[2/3]",
    offset: "md:mt-4",
    action: "Alege marimea",
    text: "Ghete split-toe din piele, marimea 42, stare foarte buna.",
  },
  {
    title: "Mavic 3 Pro",
    price: "500 RON / zi",
    category: "tools",
    image: listingImages.drone,
    aspect: "aspect-square",
    offset: "",
    action: "Vezi specificatii",
    text: "Drona cu sistem triple camera si autonomie extinsa pentru filmari cine-grade.",
  },
  {
    title: "Hasselblad 907X",
    price: "670 RON / zi",
    category: "electronics",
    image: listingImages.hasselblad,
    aspect: "aspect-[4/3]",
    offset: "xl:mt-16",
    action: "Detalii",
    text: "Camera medium format cu design modular, potrivita pentru fotografie premium.",
  },
  {
    title: "Birkin 35 Black",
    price: "1.150 RON / zi",
    category: "fashion",
    image: listingImages.bag,
    aspect: "aspect-[3/4]",
    offset: "",
    action: "Verifica autentic",
    text: "Geanta premium din piele clemence, autentificata si documentata in aplicatie.",
  },
];

export default function Archive() {
  const [menuOpen, setMenuOpen] = useState(false);
  const [activeFilter, setActiveFilter] = useState("all");
  const [progress, setProgress] = useState(0);
  const [cursor, setCursor] = useState({ x: 0, y: 0, visible: false });

  const visibleListings = useMemo(() => {
    if (activeFilter === "all") return listings;
    return listings.filter((item) => item.category === activeFilter);
  }, [activeFilter]);

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
        <title>Arhiva BorrowIt | Obiecte disponibile pentru inchiriere</title>
        <meta
          name="description"
          content="Exploreaza arhiva BorrowIt cu obiecte verificate pentru inchiriere: electronice, scule profesionale si piese premium."
        />
      </Head>

      <div
        className="fixed left-0 top-0 z-[70] h-0.5 w-full origin-left bg-[#4A70A9] transition-transform"
        style={{ transform: `scaleX(${progress})` }}
      />

      <MegaMenu open={menuOpen} onClose={() => setMenuOpen(false)} />
      <Header onMenu={() => setMenuOpen(true)} />

      <main className="w-full bg-[#f9f9f9] pt-20">
        <section className="flex flex-col items-start justify-between gap-10 px-5 py-16 md:px-20 md:py-20 lg:flex-row lg:items-end">
          <div className="max-w-3xl">
            <p className="mb-4 flex items-center gap-2 font-mono text-xs uppercase tracking-widest text-[#444748]">
              <span className="h-2 w-2 animate-pulse rounded-full bg-[#4A70A9]" />
              Inventar live / Romania
            </p>
            <h1 className="archive-title font-display font-extrabold uppercase text-black">
              Arhiva
            </h1>
          </div>

          <div className="flex flex-wrap gap-3">
            {categories.map((category) => {
              const active = activeFilter === category.id;
              return (
                <button
                  className={`border px-5 py-2 font-mono text-xs uppercase tracking-widest transition-all duration-300 ${
                    active
                      ? "border-black bg-black text-white"
                      : "border-black/20 text-black hover:border-black"
                  }`}
                  key={category.id}
                  onClick={() => setActiveFilter(category.id)}
                  type="button"
                >
                  {category.label}
                </button>
              );
            })}
          </div>
        </section>

        <section className="min-h-screen px-5 pb-32 md:px-20 md:pb-40">
          <div className="grid grid-cols-1 gap-8 transition-all duration-700 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {visibleListings.map((item) => (
              <ListingCard
                item={item}
                key={item.title}
                onCursorMove={setCursor}
                onCursorLeave={() => setCursor((current) => ({ ...current, visible: false }))}
              />
            ))}
          </div>
        </section>

        <CustomCursor cursor={cursor} />
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
          <span className="font-display text-[24px] font-bold uppercase tracking-normal text-black">
            BorrowIt
          </span>
        </Link>
        <nav className="hidden items-center gap-[clamp(2rem,5vw,6rem)] lg:flex">
          <Link className="font-mono text-xs uppercase tracking-widest text-black" href="/archive">
            Arhiva
          </Link>
          <Link className="font-mono text-xs uppercase tracking-widest text-[#444748] hover:text-black" href="/community">
            Povesti
          </Link>
          <button
            className="group flex items-center gap-3 font-mono text-xs uppercase tracking-widest text-black"
            onClick={onMenu}
            type="button"
          >
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
    <div
      className={`mega-menu-overlay fixed inset-0 z-[60] flex flex-col justify-center bg-black px-5 md:px-20 ${
        open ? "mega-menu-open" : ""
      }`}
      aria-hidden={!open}
    >
      <button
        className="absolute right-6 top-8 flex items-center gap-2 font-mono text-xs uppercase tracking-widest text-white md:right-10 md:top-10"
        onClick={onClose}
        type="button"
      >
        <span className="material-symbols-outlined">close</span>
        Inchide
      </button>
      <nav className="flex flex-col space-y-6">
        {links.map((link) => (
          <Link
            className={`font-display text-5xl font-bold transition-all duration-300 md:text-7xl ${
              link.href === "/archive" ? "text-[#8FABD4]" : "text-white hover:text-[#8FABD4]"
            }`}
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

function ListingCard({ item, onCursorMove, onCursorLeave }) {
  const [transform, setTransform] = useState("perspective(1000px) rotateX(0deg) rotateY(0deg) scale(1)");

  const handleMouseMove = (event) => {
    const rect = event.currentTarget.getBoundingClientRect();
    const x = event.clientX - rect.left;
    const y = event.clientY - rect.top;
    const rotateX = ((y - rect.height / 2) / (rect.height / 2)) * -8;
    const rotateY = ((x - rect.width / 2) / (rect.width / 2)) * 8;

    setTransform(`perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) scale(1.02)`);
    onCursorMove({ x: event.clientX, y: event.clientY, visible: true });
  };

  const handleMouseLeave = () => {
    setTransform("perspective(1000px) rotateX(0deg) rotateY(0deg) scale(1)");
    onCursorLeave();
  };

  return (
    <article
      className={`listing-card group relative ${item.offset}`}
      onMouseLeave={handleMouseLeave}
      onMouseMove={handleMouseMove}
    >
      <div
        className="transition-all duration-500 ease-out"
        style={{ transform, transformStyle: "preserve-3d" }}
      >
        <div className={`relative overflow-hidden bg-[#eeeeee] ${item.aspect}`}>
          <img
            className="h-full w-full object-cover transition-transform duration-700 group-hover:scale-110"
            src={item.image}
            alt={item.title}
          />
          <div className="pointer-events-none absolute inset-0 flex items-center justify-center bg-black/25 opacity-0 transition-opacity duration-500 group-hover:opacity-100">
            <span className="border border-white px-4 py-2 font-mono text-xs uppercase tracking-widest text-white backdrop-blur-sm">
              {item.action}
            </span>
          </div>
        </div>
        <div className="mt-6">
          <div className="mb-2 flex items-start justify-between gap-4">
            <h3 className="text-2xl font-medium uppercase leading-8 tracking-normal text-black">
              {item.title}
            </h3>
            <span className="shrink-0 pt-2 font-mono text-xs uppercase tracking-widest text-[#444748]">
              {item.price}
            </span>
          </div>
          <p className="text-base leading-6 text-[#444748]/80">{item.text}</p>
        </div>
      </div>
    </article>
  );
}

function CustomCursor({ cursor }) {
  return (
    <div
      className={`pointer-events-none fixed left-0 top-0 z-[100] hidden h-8 w-8 -translate-x-1/2 -translate-y-1/2 items-center justify-center mix-blend-difference transition-opacity duration-300 md:flex ${
        cursor.visible ? "opacity-100" : "opacity-0"
      }`}
      style={{ transform: `translate(${cursor.x}px, ${cursor.y}px) translate(-50%, -50%)` }}
    >
      <div
        className={`h-full w-full rounded-full border-2 border-white transition-transform duration-300 ${
          cursor.visible ? "scale-[2]" : "scale-50"
        }`}
      />
      <span
        className={`material-symbols-outlined absolute text-[12px] text-white transition-opacity duration-300 ${
          cursor.visible ? "opacity-100" : "opacity-0"
        }`}
      >
        add
      </span>
    </div>
  );
}

function Footer() {
  return (
    <footer className="w-full bg-black px-5 py-32 md:px-20 md:py-40">
      <div className="mb-12 flex flex-col items-start justify-between gap-10 border-b border-white/10 pb-12 lg:flex-row lg:items-end">
        <h2 className="max-w-4xl font-display text-6xl font-extrabold uppercase leading-none text-white md:text-[120px]">
          Gata sa imparti?
        </h2>
        <Link
          className="bg-[#4A70A9] px-12 py-6 font-mono text-xs uppercase tracking-widest text-white transition-colors duration-300 hover:bg-white hover:text-[#30578F]"
          href="/download"
        >
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
          <Link href="/archive">Arhiva</Link>
        </FooterColumn>
        <div className="flex flex-col gap-6 md:col-span-2">
          <p className="font-mono text-xs uppercase tracking-widest text-white/60">Newsletter</p>
          <form className="relative flex w-full items-center border-b border-white/20">
            <input
              className="w-full bg-transparent py-4 text-xl leading-8 text-white outline-none transition-colors placeholder:text-white/35"
              placeholder="Introdu adresa de email"
              type="email"
            />
            <button className="material-symbols-outlined text-white" type="submit">
              arrow_forward
            </button>
          </form>
        </div>
      </div>
      <div className="flex flex-col justify-between gap-8 border-t border-white/5 pt-8 md:flex-row">
        <span className="font-mono text-xs uppercase tracking-widest text-white/40">
          © 2026 BorrowIt. Construit pentru economia de sharing.
        </span>
        <div className="flex flex-wrap gap-6">
          <Link className="font-mono text-xs uppercase tracking-widest text-white/40" href="/privacy-policy">
            Confidentialitate
          </Link>
          <Link className="font-mono text-xs uppercase tracking-widest text-white/40" href="/terms-and-conditions">
            Termeni
          </Link>
          <Link className="font-mono text-xs uppercase tracking-widest text-white/40" href="/support">
            Suport
          </Link>
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
