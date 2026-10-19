/* eslint-disable @next/next/no-img-element */
import Head from "next/head";
import Link from "next/link";
import BrandLogo from "../components/BrandLogo";
import { useMemo, useState } from "react";

const cardAspects = ["aspect-[4/5]", "aspect-[3/4]", "aspect-square", "aspect-[4/3]"];
const cardOffsets = ["", "md:mt-12", "", "xl:mt-16"];

export async function getServerSideProps({ res }) {
  try {
    const apiUrl = (process.env.BACKEND_API_URL || "http://localhost:3000/api").replace(/\/$/, "");
    const response = await fetch(`${apiUrl}/products`, {
      cache: "no-store",
      signal: AbortSignal.timeout(10000),
    });
    if (!response.ok) throw new Error(`Products API returned ${response.status}`);

    const products = await response.json();
    if (!Array.isArray(products)) throw new Error("Products API returned an invalid list");

    const listings = products
      .filter((product) => product && product.isClosedByAdmin !== true)
      .map((product, index) => {
        const image = Array.isArray(product.images)
          ? product.images.find((item) => item?.url && item.type !== "video" && item.contentType?.startsWith("image/"))
          : null;
        return {
          id: String(product._id ?? product.id ?? ""),
          slug: String(product.slug ?? ""),
          title: String(product.title ?? ""),
          category: String(product.categorySlug ?? ""),
          categoryLabel: String(product.category ?? product.categorySlug ?? ""),
          image: image?.url ?? null,
          aspect: cardAspects[index % cardAspects.length],
          offset: cardOffsets[index % cardOffsets.length],
          price: `${new Intl.NumberFormat("ro-RO", { maximumFractionDigits: 2 }).format(Number(product.pricePerDay) || 0)} RON / ZI`,
          text: String(product.description ?? ""),
        };
      })
      .filter((item) => item.id && item.slug && item.title);

    const categories = [
      { id: "all", label: "Toate anunțurile" },
      ...Array.from(new Map(listings.filter((item) => item.category).map((item) => [
        item.category,
        { id: item.category, label: item.categoryLabel },
      ])).values()),
    ];

    return { props: { listings, categories, loadError: false } };
  } catch (error) {
    console.error("Could not load archive listings:", error);
    res.statusCode = 503;
    return {
      props: {
        listings: [],
        categories: [{ id: "all", label: "Toate anunțurile" }],
        loadError: true,
      },
    };
  }
}

export default function Archive({ listings, categories, loadError }) {
  const [menuOpen, setMenuOpen] = useState(false);
  const [activeFilter, setActiveFilter] = useState("all");
  const [cursor, setCursor] = useState({ x: 0, y: 0, visible: false });

  const visibleListings = useMemo(() => {
    if (activeFilter === "all") return listings;
    return listings.filter((item) => item.category === activeFilter);
  }, [activeFilter, listings]);


  return (
    <>
      <Head>
        <title>Anunțuri PINLEND | Obiecte disponibile pentru închiriere</title>
        <meta
          name="description"
          content="Explorează anunțurile PINLEND cu obiecte verificate pentru închiriere."
        />
      </Head>

      <MegaMenu open={menuOpen} onClose={() => setMenuOpen(false)} />
      <Header onMenu={() => setMenuOpen(true)} />

      <main className="w-full bg-[#f9f9f9] pt-20">
        <section className="flex flex-col items-start gap-8 px-5 py-16 md:px-20 md:py-20">
          <div>
            <h1 className="archive-title font-display font-extrabold uppercase text-black">
              Anunțuri
            </h1>
          </div>

          <div className="flex w-full flex-wrap gap-3">
            {categories.map((category) => {
              const active = activeFilter === category.id;
              return (
                <button
                  className={`rounded-full border px-5 py-2 font-mono text-xs uppercase tracking-widest transition-all duration-300 ${
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
          {loadError ? (
            <div className="py-16 text-center text-[#444748]">
              <p>Nu am putut încărca anunțurile. Încearcă din nou.</p>
              <Link className="mt-6 inline-block border border-black px-5 py-2 font-mono text-xs uppercase tracking-widest text-black" href="/archive">
                Reîncearcă
              </Link>
            </div>
          ) : visibleListings.length === 0 ? (
            <p className="py-16 text-center text-[#444748]">Nu există anunțuri în această categorie.</p>
          ) : (
            <div className="grid grid-cols-1 gap-8 transition-all duration-700 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
              {visibleListings.map((item) => (
                <ListingCard
                  item={item}
                  key={item.id}
                  onCursorMove={setCursor}
                  onCursorLeave={() => setCursor((current) => ({ ...current, visible: false }))}
                />
              ))}
            </div>
          )}
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
        <BrandLogo />
        <nav className="hidden items-center gap-[clamp(2rem,5vw,6rem)] lg:flex">
          <Link className="font-mono text-xs uppercase tracking-widest text-black" href="/archive">
            Anunțuri
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
        <Link aria-label="Contul meu" className="flex h-8 w-8 items-center justify-center rounded-full bg-black" href="/account">
          <span className="material-symbols-outlined text-[18px] text-white">person</span>
        </Link>
      </div>
    </header>
  );
}

function MegaMenu({ open, onClose }) {
  const links = [
    { label: "Acasa", href: "/" },
    { label: "Functionalitati", href: "/features" },
    { label: "Anunțuri", href: "/archive" },
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
      <Link
        aria-label={`Vezi detaliile anunțului ${item.title}`}
        href={`/anunt/${encodeURIComponent(item.slug)}`}
        className="block transition-all duration-500 ease-out"
        style={{ transform, transformStyle: "preserve-3d" }}
      >
        <div className={`relative overflow-hidden rounded-xl bg-[#eeeeee] ${item.aspect}`}>
          {item.image ? (
            <img
              className="h-full w-full object-cover transition-transform duration-700 group-hover:scale-110"
              src={item.image}
              alt={item.title}
            />
          ) : (
            <div className="flex h-full w-full items-center justify-center font-mono text-xs uppercase tracking-widest text-[#444748]">
              Fără imagine
            </div>
          )}
          <div className="pointer-events-none absolute inset-0 flex items-center justify-center bg-black/25 opacity-0 transition-opacity duration-500 group-hover:opacity-100">
            <span className="border border-white px-4 py-2 font-mono text-xs uppercase tracking-widest text-white backdrop-blur-sm">
              Vezi detalii
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
          <p className="line-clamp-3 text-base leading-6 text-[#444748]/80">{item.text}</p>
        </div>
      </Link>
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
          <Link href="/archive">Anunțuri</Link>
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
          © 2026 PINLEND. Construit pentru economia de sharing.
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
