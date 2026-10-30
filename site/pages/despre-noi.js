/* eslint-disable @next/next/no-img-element */
import Head from "next/head";
import Link from "next/link";
import PublicHeader from "../components/PublicHeader";
import PublicFooter from "../components/PublicFooter";
import { useEffect } from "react";
import { useRouter } from "next/router";

const images = {
  chair:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuAtgQOPtSqsgqb_M42r6q_y_uuvZf_doQ2rxXI4ejJAAd89UkbMwZ1aQuFwMREtC-7AB4B0zaphmGITuC0leC-OTuAYHNKQ5HlSxmwI2_p0uQu4giq740jyORsn6EDOdGuuiabwnHZhfBxw8tywS8JBrkaZJXaxBYAuefXIHPF82zuvartfG5RqXmgchP9_menPPrmq5MHYmvAs8zLy1W_NldTlnd5RPr_ghYOmKt--0tU-CH6sCLPTIUaCAB8dcwfw0LfChhY86Wo",
  fabric:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuDNwyufGstvX6r-5N3LCQHmREFe5SV3rKFuqIS53Q2IL35T6IGlra4Ilu9mLE56d7vTqdNulN6Z6CyXUCn4qZthi4bQdZ0izPwV7yKSQ0kd9hGiF_9CxPEeyBZ0yBvnaAQDBWktb5rrQpQm_H6cPMZSbkLJaBJkmd86JbbkNla4yk2VgZyCc-5cAhGahJY25QYrmhoRiPpyob6w0NAymGqRfAbDqXqSP1iVejOqflJlRYiHpaTBYlDGn0MGJANbWtssXFkx23ArmKE",
  dashboard:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuCWm1bARJg17gDENBM8bN1LS9H1IxjNCMH8Wno7yIesL6fviVeQJQnFA-8hLD1sq6sIpc0KzZM7HtsOQMsbSzg14rEmQOOT8ST6hQr8FXm_gv69p3RMy9cA9IMFZ7jlPpxw3z0u0Ja9RfuDmFFbpwA93YMp5r4dZVj-O8u-i1GaYJjrkOLlEHRsqiDAWBWmEBuCkEuai2xxahL9TmJDQgVWCzEtrf-yiHt-zIkgE-te6zoQoElelaYrxDoqSd8iUaoWKoIHk7_jfaY",
  community:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuDoTxCJbPVCzPfQx6x1GTAwtte-BdAJEJRoF2-ip5A0ZunpaVJrjhIyWLDB9QAoyILKw5Le0YqzTzNdsuOw1CGa9NCUIzLAo7Sc9EddJUoVrpV9M0mZMkMIEYtmq894gE-kwKJECC9QgfWCIo24rR3xaCY83HYwGw2ota-HVW-osWZUmFGhLU6bxvd0CYo00nVnfuI1aXMb4JgUHkQkTH_LVhxeKRE0tKbySvW4AB_MPBq3D959RBBsxrN0d5PuFq1Gn43oM_PWDyM",
  house:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuD8ya4pMcY2U57Xg626iw1wbyldOPVuIW1NOVonBh_8-RGZlfFcquG3yW-Y44f26KVxucNw3Truw_wipIMZcYkWSin0iA9HkWCBzfECaHjkabo7IBU7jMknrUOUV3moG_ZcgdHShF0M3w-G5KU6IN6LVDLf19ZORO0KMb5bJpj_kFx7ZQPLfHiiSCxzxRscg0c0fvJ23ogwm8m2AF7O10LxxUAvfj0HD2S_6OPhPlK0DleavNXi6gz5k3kRLtmlEYSYPl8tF-QaNfE",
};

const features = [
  {
    icon: "verified_user",
    image: images.fabric,
    title: "Verificare de nivel inalt",
    text: "Fiecare membru si fiecare obiect trece printr-un proces riguros de verificare, pentru incredere reala intre utilizatori.",
  },
  {
    icon: "travel_explore",
    image: images.dashboard,
    title: "Predare si retur simple",
    text: "Fluxuri clare pentru predare, retur, garantii si documentare digitala, gandite pentru obiecte valoroase si inchirieri fara stres.",
  },
  {
    icon: "group_work",
    image: images.community,
    title: "Reputatie in comunitate",
    text: "Construieste incredere prin recenzii, verificari si inchirieri reusite. Cu cat esti mai activ, cu atat ai acces la mai multe obiecte.",
  },
];

export default function DespreNoi() {
  const en = useRouter().locale === "en";

  useEffect(() => {
    const heroLines = document.querySelectorAll(".hero-line");
    const heroSubs = document.querySelectorAll(".hero-sub");
    const reveals = document.querySelectorAll(".reveal-text");

    const introTimer = window.setTimeout(() => {
      heroLines.forEach((line) => {
        line.style.transform = "translateY(0)";
      });
      heroSubs.forEach((sub) => {
        sub.style.opacity = "1";
        sub.style.transform = "translateY(0)";
      });
    }, 300);

    reveals.forEach((el) => {
      el.style.opacity = "0";
      el.style.transform = "translateY(30px)";
      el.style.transition = "all 1s cubic-bezier(0.23, 1, 0.32, 1)";
    });

    const handleScroll = () => {
      reveals.forEach((el) => {
        const revealTop = el.getBoundingClientRect().top;
        if (revealTop < window.innerHeight - 150) {
          el.style.opacity = "1";
          el.style.transform = "translateY(0)";
        }
      });
    };

    const counterObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          entry.target.querySelectorAll(".counter").forEach((counter) => {
            const target = Number(counter.getAttribute("data-target"));
            const duration = 1600;
            const increment = target / (duration / 16);
            let current = 0;

            const updateCounter = () => {
              current += increment;
              if (current < target) {
                counter.textContent = Math.ceil(current);
                requestAnimationFrame(updateCounter);
              } else {
                counter.textContent = String(target);
              }
            };

            updateCounter();
          });
          counterObserver.unobserve(entry.target);
        });
      },
      { threshold: 0.45 },
    );

    const impactSection = document.querySelector("#impact-section");
    if (impactSection) counterObserver.observe(impactSection);
    window.addEventListener("scroll", handleScroll, { passive: true });
    handleScroll();

    return () => {
      window.clearTimeout(introTimer);
      window.removeEventListener("scroll", handleScroll);
      counterObserver.disconnect();
    };
  }, []);

  return (
    <>
      <Head>
        <title>{en ? "About us | PINLEND" : "Despre noi | PINLEND"}</title>
        <meta
          name="description"
          content={en ? "PINLEND helps you rent and share verified items safely and simply in your community." : "PINLEND este platforma prin care inchiriezi si oferi obiecte verificate, sigur si simplu, in comunitatea ta."}
        />
      </Head>

      <PublicHeader current="/despre-noi" />

      <main className="w-full pt-20">
        <Hero en={en} />
        <Vision en={en} />
        <Impact en={en} />
        <Features en={en} />
        <ArchiveBreak en={en} />
      </main>

      <PublicFooter />
    </>
  );
}

function Hero({ en }) {
  return (
    <section className="relative flex min-h-[calc(100vh+180px)] items-center overflow-hidden px-5 py-24 md:px-20">
      <div className="pointer-events-none relative z-10 grid w-full grid-cols-12 gap-8">
        <div className="col-span-12 lg:col-span-10">
          <h1 className="font-display text-[18vw] font-extrabold uppercase leading-[0.92] tracking-normal text-black md:text-[120px]">
            {(en ? ["OWN LESS.", "USE MORE.", "SHARE BETTER."] : ["DETINE MAI", "PUTIN.", "ACCESEAZA TOT."]).map((line, index) => (
              <span className="block overflow-hidden" key={line}>
                <span
                  className={`hero-line inline-block transition-transform duration-1000 ease-out ${
                    index === 2 ? "text-outline" : ""
                  }`}
                  style={{ transitionDelay: `${100 + index * 180}ms` }}
                >
                  {line}
                </span>
              </span>
            ))}
          </h1>
        </div>
        <div className="col-span-12 mt-12 lg:col-span-5 lg:col-start-8">
          <p className="hero-sub max-w-md text-xl leading-8 text-[#1a1c1c] transition-all delay-700 duration-1000">
            {en ? "PINLEND lets you rent quality items when you need them and share yours when they are sitting unused." : "PINLEND este platforma prin care inchiriezi obiecte de calitate doar cand ai nevoie de ele si le oferi mai departe atunci cand stau nefolosite."}
          </p>
          <div className="hero-sub mt-8 flex flex-col gap-5 transition-all delay-1000 duration-1000 sm:flex-row sm:items-center sm:gap-8">
            <a className="inline-flex justify-center bg-black px-10 py-5 font-mono text-xs uppercase tracking-widest text-white transition-all duration-300 hover:bg-[#30578F]" href="#impact-section">
              {en ? "Explore listings" : "Explorează anunțurile"}
            </a>
            <span className="flex items-center gap-2 font-mono text-xs uppercase tracking-widest">
              {en ? "Scroll to learn more" : "Deruleaza pentru detalii"}
              <span className="material-symbols-outlined animate-bounce">arrow_downward</span>
            </span>
          </div>
        </div>
      </div>
      <div className="absolute right-10 top-1/2 hidden -translate-y-1/2 [writing-mode:vertical-rl] lg:block">
        <span className="font-mono text-xs uppercase tracking-[0.5em] text-[#444748]">
          {en ? "Global community - 2026" : "Comunitate globala - 2026"}
        </span>
      </div>
    </section>
  );
}

function Vision({ en }) {
  return (
    <section className="relative flex min-h-screen flex-col justify-center overflow-hidden bg-black px-5 py-32 md:px-20 md:py-40">
      <div className="grid grid-cols-12 gap-8">
        <div className="col-span-1 -mt-10 font-mono text-7xl text-white/20">01</div>
        <div className="col-span-11 lg:col-span-8 lg:col-start-3">
          <p className="mb-8 font-mono text-xs uppercase tracking-widest text-[#8FABD4]">
            {en ? "Our vision" : "Viziunea"}
          </p>
          <h2 className="reveal-text font-display text-5xl font-bold leading-tight text-white md:text-7xl">
            {en ? "A circular economy built for practical people. We replace unnecessary ownership with flexible access and turn unused items into shared experiences." : "O economie circulara construita pentru oameni practici. Inlocuim proprietatea inutila cu acces flexibil si transformam obiectele nefolosite in experiente comune."}
          </h2>
        </div>
      </div>
    </section>
  );
}

function Impact({ en }) {
  return (
    <section className="relative bg-[#f9f9f9] px-5 py-32 md:px-20 md:py-40" id="impact-section">
      <div className="flex flex-col items-start justify-between gap-20 lg:flex-row">
        <div className="w-full lg:sticky lg:top-40 lg:w-1/2">
          <h3 className="mb-12 font-display text-5xl font-bold uppercase text-black md:text-7xl">
            {en ? "Measurable impact" : "Impact masurabil"}
          </h3>
          <div className="flex flex-col gap-12">
            <Stat label={en ? "Carbon saved" : "Carbon redus"} target="42" suffix="%" />
            <Stat label={en ? "Active exchanges" : "Schimburi active"} target="185" suffix="K" />
          </div>
        </div>
        <div className="flex w-full flex-col gap-8 pt-8 lg:w-1/3 lg:pt-20">
          <div className="group relative aspect-[4/5] overflow-hidden bg-[#eeeeee]">
            <img
              className="h-full w-full object-cover transition-transform duration-700 group-hover:scale-110"
              src={images.chair}
              alt={en ? "Premium item in a minimalist space" : "Obiect premium intr-un spatiu minimalist, fotografiat editorial"}
            />
            <div className="absolute inset-0 flex items-center justify-center bg-black/20 opacity-0 transition-opacity group-hover:opacity-100">
              <span className="bg-black px-6 py-3 font-mono text-xs uppercase tracking-widest text-white">
                {en ? "View item" : "Vezi obiectul"}
              </span>
            </div>
          </div>
          <p className="text-base leading-6 text-[#444748]">
            {en ? "Each PINLEND rental reduces the need to make something new. Items are used more efficiently, and the community gets access to great things with less waste." : "Fiecare inchiriere PINLEND reduce nevoia de productie noua. Obiectele sunt folosite mai eficient, iar comunitatea castiga acces la lucruri bune fara risipa."}
          </p>
        </div>
      </div>
    </section>
  );
}

function Stat({ label, target, suffix }) {
  return (
    <div className="border-b border-[#c4c7c7] pb-8">
      <span className="font-mono text-xs uppercase tracking-widest text-[#444748]">{label}</span>
      <div className="flex items-baseline gap-4">
        <span className="counter font-display text-[96px] font-bold leading-none text-black md:text-[120px]" data-target={target}>
          0
        </span>
        <span className="font-display text-6xl font-bold text-black">{suffix}</span>
      </div>
    </div>
  );
}

function Features({ en }) {
  return (
    <section className="relative overflow-hidden bg-black px-5 py-32 md:px-20 md:py-40" id="features">
      <div className="mb-24 flex flex-col justify-between gap-12 lg:flex-row lg:items-end">
        <div className="max-w-2xl">
          <span className="mb-6 block font-mono text-xs uppercase tracking-widest text-[#8FABD4]">
            {en ? "Rethinking access" : "Redefinim accesul"}
          </span>
          <h2 className="font-display text-5xl font-bold uppercase text-white md:text-7xl">
            {en ? "The ecosystem" : "Ecosistemul"}
          </h2>
        </div>
        <a className="group flex items-center gap-4 font-mono text-xs uppercase tracking-widest text-white" href="#">
          {en ? "Explore all features" : "Exploreaza toate functionalitatile"}
          <span className="flex h-12 w-12 items-center justify-center rounded-full border border-white/20 transition-all group-hover:bg-[#4A70A9] group-hover:text-white">
            <span className="material-symbols-outlined">arrow_forward</span>
          </span>
        </a>
      </div>
      <div className="grid grid-cols-1 gap-12 md:grid-cols-2 lg:grid-cols-3">
        {features.map((feature, index) => (
          <article
            className="flex flex-col gap-8 transition-transform duration-500 hover:-translate-y-4"
            style={{ transform: `translateY(${index * 48}px)` }}
            key={feature.title}
          >
            <div className="relative h-80 overflow-hidden bg-[#e2e2e2]">
              <img
                className="h-full w-full object-cover grayscale transition-all duration-700 hover:grayscale-0"
                src={feature.image}
                alt={en ? ["Verified sharing", "Easy handover and return", "Community reputation"][index] : feature.title}
              />
              <div className="absolute left-6 top-6 flex h-10 w-10 items-center justify-center bg-black">
                <span className="material-symbols-outlined text-white">{feature.icon}</span>
              </div>
            </div>
            <div>
              <h4 className="mb-4 text-3xl font-medium leading-10 text-white">{en ? ["Thorough verification", "Simple handover and return", "Community reputation"][index] : feature.title}</h4>
              <p className="text-base leading-6 text-white/60">{en ? ["Members and items go through checks designed to build trust between people.", "Clear steps for handover, return, deposits, and digital records make valuable rentals easier.", "Build trust through reviews, checks, and successful rentals. The more active you are, the more you can access."][index] : feature.text}</p>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}

function ArchiveBreak({ en }) {
  const steps = [
    {
      number: "01",
      title: "Alegi obiectul",
      text: "Cauti in comunitate, verifici pozele, pretul pe zi si ratingul proprietarului.",
      icon: "search",
    },
    {
      number: "02",
      title: "Rezervi perioada",
      text: "Selectezi zilele, vezi costul total si garantia inainte sa confirmi.",
      icon: "calendar_month",
    },
    {
      number: "03",
      title: "Predare verificata",
      text: "Identitatea, contractul si returul sunt documentate digital in aplicatie.",
      icon: "verified_user",
    },
  ];

  return (
    <section className="relative overflow-hidden bg-black px-5 py-32 md:px-20 md:py-40">
      <div className="absolute right-0 top-0 h-full w-1/2 bg-[radial-gradient(circle_at_center,#4A70A933,transparent_60%)]" />
      <div className="relative z-10 grid grid-cols-1 gap-14">
        <div className="min-w-0 max-w-6xl">
          <p className="mb-6 font-mono text-xs uppercase tracking-widest text-[#8FABD4]">
            {en ? "How it works" : "Cum functioneaza"}
          </p>
          <h2 className="section-flow-title font-display font-extrabold uppercase text-white">
            <span className="block">{en ? "Rent with clarity," : "Inchiriere clara,"}</span>
            <span className="block">{en ? "from start to finish." : "fara improvizatii."}</span>
          </h2>
          <p className="mt-8 max-w-[680px] text-lg leading-8 text-white/60 md:text-xl">
            {en ? "PINLEND brings search, booking, identity verification, and contracts into one simple flow built on trust between people." : "PINLEND leaga cautarea, rezervarea, verificarea identitatii si contractul intr-un flux simplu, construit pentru incredere intre oameni reali."}
          </p>
        </div>

        <div className="min-w-0">
          <div className="grid gap-5 lg:grid-cols-3">
            {steps.map((step, index) => (
              <article
                className="group grid min-w-0 grid-cols-[56px_1fr] gap-4 border border-white/10 bg-white/[0.03] p-5 transition-colors hover:border-[#4A70A9]/70 hover:bg-white/[0.06] sm:grid-cols-[72px_1fr] md:grid-cols-[96px_64px_1fr] md:gap-5 md:p-7 lg:grid-cols-1"
                key={step.number}
              >
                <span className="font-display text-4xl font-extrabold text-white/20 transition-colors group-hover:text-[#8FABD4]">
                  {step.number}
                </span>
                <span className="hidden h-14 w-14 items-center justify-center rounded-full border border-white/10 text-[#8FABD4] md:flex">
                  <span className="material-symbols-outlined">{step.icon}</span>
                </span>
                <div>
                  <h3 className="text-2xl font-semibold text-white">
                    {en ? ["Choose an item", "Book your dates", "Verified handover"][index] : step.title}
                  </h3>
                  <p className="mt-2 text-base leading-6 text-white/55">
                    {en ? ["Browse the community and check photos, daily price, and owner ratings.", "Choose your dates and see the total price and deposit before confirming.", "Identity, contract, and return are documented in the app."][index] : step.text}
                  </p>
                </div>
              </article>
            ))}
          </div>

          <div className="mt-8 grid gap-5 border border-[#4A70A9]/50 bg-[#30578F] p-6 text-white md:grid-cols-[1fr_auto] md:items-end">
            <div>
              <p className="font-mono text-xs uppercase tracking-widest text-white/65">
                {en ? "Example from the app" : "Exemplu din app"}
              </p>
              <h3 className="mt-3 text-3xl font-bold">
                PlayStation 5 Digital Edition
              </h3>
              <div className="mt-5 flex flex-wrap gap-3">
                <span className="rounded-full bg-white px-4 py-2 text-sm font-bold text-[#30578F]">
                  {en ? "85 RON / day" : "85 RON / zi"}
                </span>
                <span className="rounded-full border border-white/25 px-4 py-2 text-sm font-bold">
                  {en ? "300 RON deposit" : "Garantie 300 RON"}
                </span>
                <span className="rounded-full border border-white/25 px-4 py-2 text-sm font-bold">
                  {en ? "Verified owner" : "Proprietar verificat"}
                </span>
              </div>
            </div>
            <a
              className="inline-flex justify-center bg-white px-8 py-4 font-mono text-xs uppercase tracking-widest text-[#30578F] transition-colors hover:bg-black hover:text-white"
              href="#features"
            >
              {en ? "Explore safety" : "Vezi siguranta"}
            </a>
          </div>
        </div>
      </div>
    </section>
  );
}
