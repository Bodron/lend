/* eslint-disable @next/next/no-img-element */
import Head from "next/head";
import Link from "next/link";
import { useEffect, useState } from "react";

const images = {
  qr:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuBgXlqZfPR0juTeqw2FA0S_oaDu2RdmPj_Ekw9RW7rfgn-v5X9OYsMpWcAnAGnjFVZab-MIpn4BE3rpqWSLacbAsUg7qwFmMzkDg04ZCL84TSrskusrDsyBzPG1Kq_yPJQkuzFnLuZJpMn06eTSlPj5wlreKHNP-Q5tmtHP6EHTExWnCiY7kPO1wAvm1VZFuhISv0oQS5z7Bb5q9X9fnguSIGc8dmdH54JSeupPGg1wwxDND4DxxcktQd4Bl-9Q0SbIg5uYGwU1ftw",
  phone:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuC8nfC5SPEvkg3ouHqbt1XgXINOC92mi8ug5eZOJ0jLasBzyrsuY7tqNDHrAD9OTGMWqHh6t6viR1uD0Pd-8E--7Iit_VgmQ2_34hcOn89WRSo5RzAmhG4aEzjeKx6mK5R_05oTULIIz5LUSNisbz36iYQHrUKBltseSOX04mj8AO90mMuRd7jC_7DN26IBYkweexXEbkSTPiDO5MT7bq-VYhAYWiIQLo-G8Am2PryX4yhBa8db-8tQ9xL7tnOBsMkDGzbkbPhiLvs",
};

export default function Download() {
  const [menuOpen, setMenuOpen] = useState(false);
  const [progress, setProgress] = useState(0);
  const [buttonTransform, setButtonTransform] = useState("translate(0px, 0px)");
  const [labelTransform, setLabelTransform] = useState("translate(0px, 0px)");
  const [phoneTransform, setPhoneTransform] = useState("perspective(1000px) rotateY(0deg) rotateX(0deg)");
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
      setProgress(maxScroll > 0 ? window.scrollY / maxScroll : 0);
    };

    const handleMouseMove = (event) => {
      const x = (window.innerWidth / 2 - event.clientX) / 40;
      const y = (window.innerHeight / 2 - event.clientY) / 40;
      setPhoneTransform(`perspective(1000px) rotateY(${-x}deg) rotateX(${y}deg)`);
    };

    window.addEventListener("scroll", handleScroll, { passive: true });
    window.addEventListener("mousemove", handleMouseMove);
    handleScroll();
    const timer = window.setTimeout(() => setVisible(true), 120);

    return () => {
      window.clearTimeout(timer);
      window.removeEventListener("scroll", handleScroll);
      window.removeEventListener("mousemove", handleMouseMove);
    };
  }, []);

  const handleMagneticMove = (event) => {
    const rect = event.currentTarget.getBoundingClientRect();
    const x = event.clientX - rect.left - rect.width / 2;
    const y = event.clientY - rect.top - rect.height / 2;
    setButtonTransform(`translate(${x * 0.3}px, ${y * 0.3}px)`);
    setLabelTransform(`translate(${x * 0.1}px, ${y * 0.1}px)`);
  };

  const resetMagnetic = () => {
    setButtonTransform("translate(0px, 0px)");
    setLabelTransform("translate(0px, 0px)");
  };

  return (
    <>
      <Head>
        <title>Descarca BorrowIt | Aplicatia pentru inchirieri intre oameni</title>
        <meta
          name="description"
          content="Descarca aplicatia BorrowIt si inchiriaza obiecte verificate sau publica propriile obiecte in comunitate."
        />
      </Head>

      <div
        className="fixed left-0 top-0 z-[70] h-0.5 w-full origin-left bg-[#4A70A9] transition-transform"
        style={{ transform: `scaleX(${progress})` }}
      />

      <MegaMenu open={menuOpen} onClose={() => setMenuOpen(false)} />
      <Header onMenu={() => setMenuOpen(true)} />

      <main className="w-full bg-[#f9f9f9] pt-20">
        <div className="flex w-full flex-col">
          <section
            className={`relative grid min-h-[921px] w-full grid-cols-1 overflow-hidden bg-[#f9f9f9] transition-all duration-1000 lg:grid-cols-12 ${
              visible ? "translate-y-0 opacity-100" : "translate-y-10 opacity-0"
            }`}
          >
            <div className="z-10 flex flex-col justify-center px-5 py-24 md:px-20 md:py-40 lg:col-span-7">
              <div className="mb-8 flex items-center gap-4">
                <span className="h-px w-12 bg-black" />
                <span className="font-mono text-xs uppercase tracking-widest text-[#444748]">
                  Disponibila acum
                </span>
              </div>
              <h1 className="download-display-2xl mb-12 font-display font-extrabold text-black">
                Viitorul <br />
                <span className="italic text-outline-blue">se imparte.</span>
              </h1>
              <p className="mb-16 max-w-xl text-xl leading-8 text-[#444748]">
                Intra intr-o comunitate de oameni practici. Inchiriaza obiecte bune, publica propria arhiva si redefineste proprietatea pentru viata moderna.
              </p>
              <div className="flex flex-wrap items-center gap-8">
                <div
                  className="-m-10 p-10"
                  onMouseLeave={resetMagnetic}
                  onMouseMove={handleMagneticMove}
                >
                  <button
                    className="group relative flex items-center gap-4 overflow-hidden bg-black px-12 py-8 font-mono text-xs uppercase tracking-widest text-white transition-transform duration-300 ease-out hover:scale-110"
                    style={{ transform: buttonTransform }}
                    type="button"
                  >
                    <span className="relative z-10 transition-transform" style={{ transform: labelTransform }}>
                      Descarca aplicatia
                    </span>
                    <span className="material-symbols-outlined relative z-10 transition-transform group-hover:translate-x-2">
                      arrow_downward
                    </span>
                    <span className="absolute inset-0 translate-y-full bg-[#4A70A9] transition-transform duration-500 group-hover:translate-y-0" />
                  </button>
                </div>
                <div className="flex flex-col gap-2">
                  <span className="font-mono text-[10px] uppercase tracking-normal text-[#444748]/60">
                    Scaneaza pentru acces instant
                  </span>
                  <div className="h-24 w-24 border border-[#c4c7c7] bg-[#eeeeee] p-2">
                    <img
                      className="h-full w-full grayscale transition-all duration-700 hover:grayscale-0"
                      src={images.qr}
                      alt="Cod QR pentru descarcarea aplicatiei BorrowIt"
                    />
                  </div>
                </div>
              </div>
            </div>

            <div className="relative flex min-h-[500px] items-center justify-center overflow-hidden bg-[#f3f3f4] lg:col-span-5 lg:min-h-full">
              <div className="pointer-events-none relative z-20 flex h-full w-full scale-110 items-center justify-center lg:scale-125">
                <div className="relative aspect-[9/19.5] w-[320px] transition-transform duration-1000 ease-out" style={{ transform: phoneTransform }}>
                  <img
                    className="h-full w-full object-contain drop-shadow-2xl"
                    src={images.phone}
                    alt="Telefon cu interfata aplicatiei BorrowIt"
                  />
                  <div className="absolute -right-20 -top-10 border border-[#c4c7c7]/20 bg-[#f9f9f9]/90 p-6 shadow-xl backdrop-blur-xl">
                    <div className="flex items-center gap-3">
                      <div className="flex h-10 w-10 items-center justify-center rounded-full bg-[#4A70A9] text-white">
                        <span className="material-symbols-outlined text-[20px]">verified</span>
                      </div>
                      <div className="flex flex-col">
                        <span className="font-mono text-[10px] uppercase opacity-60">Membru verificat</span>
                        <span className="text-base font-medium leading-6">9.2k online</span>
                      </div>
                    </div>
                  </div>
                  <div className="absolute -bottom-12 -left-24 hidden bg-black p-8 shadow-2xl lg:block">
                    <span className="font-display text-[40px] font-bold text-white">98%</span>
                    <p className="font-mono text-xs uppercase tracking-widest text-white/60">
                      Rating incredere
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </section>

          <section className="w-full border-y border-[#c4c7c7]/10 bg-[#eeeeee] px-5 py-24 md:px-20">
            <div className="flex flex-col items-center justify-between gap-12 lg:flex-row">
              <div className="flex max-w-sm flex-col gap-4">
                <h3 className="text-[32px] font-medium leading-10 text-black">Utilitate cross-platform</h3>
                <p className="text-base leading-6 text-[#444748]">
                  Sincronizeaza arhiva ta intre dispozitive. Optimizat pentru iOS si Android.
                </p>
              </div>
              <div className="flex flex-wrap justify-center gap-8">
                <StoreBadge icon="file_download" eyebrow="Descarca din" title="App Store" primary />
                <StoreBadge icon="shop" eyebrow="Disponibil pe" title="Google Play" />
              </div>
            </div>
          </section>

          <div className="pointer-events-none fixed right-6 top-1/2 z-50 hidden -translate-y-1/2 mix-blend-difference [writing-mode:vertical-rl] lg:block">
            <span className="font-mono text-xs uppercase tracking-[0.5em] text-white/40">
              Release.V.2.0.4.Archive
            </span>
          </div>
        </div>
      </main>

      <Footer />
    </>
  );
}

function StoreBadge({ icon, eyebrow, title, primary = false }) {
  return (
    <a
      className={`group flex items-center gap-4 overflow-hidden px-8 py-4 transition-transform hover:-translate-y-1 ${
        primary ? "bg-black text-white" : "border border-black text-black"
      }`}
      href="#"
    >
      <span className="material-symbols-outlined text-[32px]">{icon}</span>
      <div className="flex flex-col">
        <span className={`font-mono text-[10px] uppercase ${primary ? "text-white/60" : "text-[#444748]"}`}>
          {eyebrow}
        </span>
        <span className="text-xl font-medium leading-8">{title}</span>
      </div>
    </a>
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
            className={`font-display text-5xl font-bold transition-all duration-300 md:text-7xl ${link.href === "/download" ? "text-[#8FABD4]" : "text-white hover:text-[#8FABD4]"}`}
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
          <Link href="/community">Povesti</Link>
          <Link href="/archive">Arhiva</Link>
          <Link href="/download">Descarca</Link>
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
