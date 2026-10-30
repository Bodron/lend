/* eslint-disable @next/next/no-img-element */
import Head from "next/head";
import Link from "next/link";
import PublicHeader from "../components/PublicHeader";
import PublicFooter from "../components/PublicFooter";
import { useRouter } from "next/router";
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
    quote: "Increderea e greu de construit, dar PINLEND face procesul clar.",
    author: "Elena R.",
    speed: 1.5,
  },
];

export default function Community() {
  const en = useRouter().locale === "en";
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
        <title>{en ? "PINLEND community | Stories of sharing" : "Comunitate PINLEND | Povesti reale din economia de sharing"}</title>
        <meta
          name="description"
          content={en ? "Meet the PINLEND community: people, verified items, and trust built through local rentals." : "Descopera comunitatea PINLEND: povesti despre oameni, obiecte verificate si incredere construita prin inchirieri locale."}
        />
      </Head>

      <PublicHeader current="/community" />

      <main className="w-full overflow-hidden bg-[#f9f9f9] pt-20">
        <section className="relative flex flex-col items-end gap-8 px-5 py-24 md:px-20 md:py-40 lg:flex-row">
          <div className="relative z-10 lg:w-7/12">
            <span className="mb-8 block font-mono text-xs uppercase tracking-[0.2em] text-[#444748]/70">
              {en ? "Community voices" : "Vocile comunitatii"}
            </span>
            <h1 className="community-display-2xl mb-12 font-display font-extrabold text-black">
              {en ? "Stories" : "Arhiva"} <br />
              <span className="italic text-[#444748]">{en ? "worth" : "experientelor"}</span>
              <br />
              {en ? "sharing." : "impartite."}
            </h1>
            <p className="max-w-xl text-xl leading-8 text-[#444748]">
              {en ? "PINLEND is a community of people who choose smart access instead of owning things they rarely use." : "PINLEND este mai mult decat o platforma. Este o comunitate de oameni care aleg accesul inteligent in locul proprietatii inutile."}
            </p>
          </div>
          <div className="community-reveal group relative overflow-hidden lg:w-5/12">
            <img
              className="reveal-image h-[420px] w-full object-cover grayscale transition-all duration-700 ease-in-out hover:grayscale-0 md:h-[600px]"
              src={images.hero}
              alt={en ? "PINLEND community members sharing a camera" : "Membri ai comunitatii PINLEND impartind o camera foto"}
            />
            <div className="absolute bottom-0 left-0 bg-black p-6 font-mono text-xs uppercase tracking-widest text-white md:p-8">
              {en ? "Story: the creators' collective" : "Poveste: colectivul creatorilor"}
            </div>
          </div>
        </section>

        <section className="relative w-full overflow-hidden bg-black px-5 py-24 text-white md:px-20 md:py-40">
          <div className="mb-20 flex flex-col items-start justify-between gap-10 lg:flex-row">
            <div className="max-w-2xl">
              <h2 className="community-display-lg mb-6 font-display font-bold">
                {en ? "The network in motion" : "Pulsul retelei"}
              </h2>
              <p className="text-base leading-6 text-white/70">
                {en ? "Real exchanges between people. Each point represents an item put to better use, a resource saved, and a new connection." : "Schimburi reale intre oameni. Fiecare nod inseamna un obiect folosit mai bine, o resursa salvata si o conexiune noua."}
              </p>
            </div>
            <div className="flex gap-12">
              <NetworkStat value="12.4k" label={en ? "Active members" : "Noduri active"} />
              <NetworkStat value="89%" label={en ? "Repeat trust" : "Incredere repetata"} />
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
                <span className="mb-2 block font-mono text-xs uppercase tracking-widest">{en ? "Live network" : "Retea live"}</span>
                <div className="mx-auto h-px w-24 bg-[#8FABD4]" />
              </div>
            </div>
          </div>
        </section>

        <section className="space-y-32 px-5 py-24 md:px-20 md:py-40">
          <Story
            image={images.cello}
            label={en ? "Sharing music" : "Schimb muzical"}
            title={en ? "Andrei and the 18th-century cello" : "Andrei si violoncelul de secol XVIII"}
            text={en ? "I needed a professional instrument for a recording session arranged at the last minute. Through PINLEND, I quickly found a verified owner and an item with clear records." : "Aveam nevoie de un instrument profesional pentru o sesiune de inregistrare aparuta pe ultima suta de metri. Prin PINLEND am gasit rapid un proprietar verificat si un obiect documentat corect."}
            cta={en ? "Read the story" : "Citeste povestea"}
          />
          <Story
            image={images.closet}
            label={en ? "Sustainable style" : "Stil sustenabil"}
            title={en ? "The wardrobe shared across town" : "Dulapul care circula prin oras"}
            text={en ? "I had good clothes I almost never wore. Now other people use them, and I earn money without buying even more things." : "Aveam haine bune pe care nu le purtam aproape niciodata. Acum sunt folosite de alti oameni, iar eu castig bani fara sa cumpar si mai multe lucruri."}
            cta={en ? "Explore listings" : "Explorează anunțurile"}
            inverse
          />
        </section>

        <section className="relative flex h-[800px] w-full items-center justify-center overflow-hidden bg-[#eeeeee]">
          <div className="pointer-events-none absolute inset-0 opacity-10">
            <h2 className="select-none whitespace-nowrap font-display text-[20vw] font-extrabold uppercase text-black">
              {en ? "Community first Community first" : "Comunitatea pe primul loc Comunitatea pe primul loc"}
            </h2>
          </div>
          <div className="relative h-full w-full max-w-[1440px]">
            {testimonials.map((item, index) => (
              <div
                className={`absolute max-w-xs shadow-sm ${item.className.includes("p-10") ? "" : "p-8"} ${item.className}`}
                key={item.author}
                style={{ transform: `translateY(${-parallax * item.speed / 28}px)` }}
              >
                <p className="mb-4 text-base italic leading-6">{en ? ["The easiest way to use great things without filling my home with them.", "A simple exchange of tools introduced me to wonderful people.", "Trust takes time to build, and PINLEND makes the process clear."][index] : item.quote}</p>
                <span className="font-mono text-xs uppercase tracking-widest">- {item.author}</span>
              </div>
            ))}
            <div
              className="absolute bottom-[25%] right-[24%] max-w-[220px] bg-[#30578F] p-6 text-white"
              style={{ transform: `translateY(${-parallax * 3 / 28}px)` }}
            >
              <p className="font-mono text-sm font-bold uppercase leading-5">
                {en ? "1,200 kg of waste avoided this month." : "1.200 kg de risipa evitata luna aceasta."}
              </p>
            </div>
          </div>
        </section>

        <section className="bg-[#f9f9f9] px-5 py-24 text-center md:px-20 md:py-40">
          <div className="mx-auto max-w-3xl">
            <h2 className="community-display-lg mb-8 font-display font-bold text-black">
              {en ? "Write your own" : "Scrie propriul"} <span className="text-[#4A70A9]">{en ? "chapter." : "capitol."}</span>
            </h2>
            <p className="mb-12 text-xl leading-8 text-[#444748]">
              {en ? "List an item or book something you need. Join the circular economy through simple, verified steps." : "Pune un obiect la inchiriat sau rezerva ceva de care ai nevoie. Intra in economia circulara cu pasi simpli si verificati."}
            </p>
            <div className="flex flex-col justify-center gap-4 sm:flex-row">
              <Link
                className="bg-black px-10 py-5 font-mono text-xs uppercase tracking-widest text-white transition-colors hover:bg-[#30578F]"
                href="/download"
              >
                {en ? "List an item" : "Adauga un obiect"}
              </Link>
              <Link
                className="border border-black px-10 py-5 font-mono text-xs uppercase tracking-widest text-black transition-colors hover:bg-black hover:text-white"
                href="/"
              >
                {en ? "Browse listings" : "Vezi anunțurile"}
              </Link>
            </div>
          </div>
        </section>
      </main>

      <PublicFooter />
    </>
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
        <Link className="inline-flex items-center gap-4 border-b border-black pb-2 font-mono text-xs uppercase tracking-widest text-black transition-all hover:gap-8" href={inverse ? "/" : "/community"}>
          {cta}
        </Link>
      </div>
    </div>
  );
}
