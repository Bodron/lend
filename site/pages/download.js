/* eslint-disable @next/next/no-img-element */
import Head from "next/head";
import Link from "next/link";
import PublicHeader from "../components/PublicHeader";
import PublicFooter from "../components/PublicFooter";
import { useEffect, useState } from "react";
import StoreBadge from "../components/StoreBadge";
import { useRouter } from "next/router";

const images = {
  qr:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuBgXlqZfPR0juTeqw2FA0S_oaDu2RdmPj_Ekw9RW7rfgn-v5X9OYsMpWcAnAGnjFVZab-MIpn4BE3rpqWSLacbAsUg7qwFmMzkDg04ZCL84TSrskusrDsyBzPG1Kq_yPJQkuzFnLuZJpMn06eTSlPj5wlreKHNP-Q5tmtHP6EHTExWnCiY7kPO1wAvm1VZFuhISv0oQS5z7Bb5q9X9fnguSIGc8dmdH54JSeupPGg1wwxDND4DxxcktQd4Bl-9Q0SbIg5uYGwU1ftw",
  phone:
    "https://lh3.googleusercontent.com/aida-public/AB6AXuC8nfC5SPEvkg3ouHqbt1XgXINOC92mi8ug5eZOJ0jLasBzyrsuY7tqNDHrAD9OTGMWqHh6t6viR1uD0Pd-8E--7Iit_VgmQ2_34hcOn89WRSo5RzAmhG4aEzjeKx6mK5R_05oTULIIz5LUSNisbz36iYQHrUKBltseSOX04mj8AO90mMuRd7jC_7DN26IBYkweexXEbkSTPiDO5MT7bq-VYhAYWiIQLo-G8Am2PryX4yhBa8db-8tQ9xL7tnOBsMkDGzbkbPhiLvs",
};

export default function Download() {
  const en = useRouter().locale === "en";
  const [buttonTransform, setButtonTransform] = useState("translate(0px, 0px)");
  const [labelTransform, setLabelTransform] = useState("translate(0px, 0px)");
  const [phoneTransform, setPhoneTransform] = useState("perspective(1000px) rotateY(0deg) rotateX(0deg)");
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const handleMouseMove = (event) => {
      const x = (window.innerWidth / 2 - event.clientX) / 40;
      const y = (window.innerHeight / 2 - event.clientY) / 40;
      setPhoneTransform(`perspective(1000px) rotateY(${-x}deg) rotateX(${y}deg)`);
    };

    window.addEventListener("mousemove", handleMouseMove);
    const timer = window.setTimeout(() => setVisible(true), 120);

    return () => {
      window.clearTimeout(timer);
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
        <title>{en ? "Download PINLEND | Rent from people nearby" : "Descarca PINLEND | Aplicatia pentru inchirieri intre oameni"}</title>
        <meta
          name="description"
          content={en ? "Download PINLEND to rent verified items or share your own with the community." : "Descarca aplicatia PINLEND si inchiriaza obiecte verificate sau publica propriile obiecte in comunitate."}
        />
      </Head>

      <PublicHeader current="/download" />

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
                  {en ? "Available now" : "Disponibila acum"}
                </span>
              </div>
              <h1 className="download-display-2xl mb-12 font-display font-extrabold text-black">
                {en ? "The future" : "Viitorul"} <br />
                <span className="italic text-outline-blue">{en ? "is shared." : "se imparte."}</span>
              </h1>
              <p className="mb-16 max-w-xl text-xl leading-8 text-[#444748]">
                {en ? "Join a community of practical people. Rent useful items, list your own, and rethink ownership for modern life." : "Intra intr-o comunitate de oameni practici. Inchiriaza obiecte bune, publică propriile anunțuri si redefineste proprietatea pentru viata moderna."}
              </p>
              <div className="flex flex-wrap items-center gap-8">
                <div
                  className="-m-10 p-10"
                  onMouseLeave={resetMagnetic}
                  onMouseMove={handleMagneticMove}
                >
                  <button
                    className="group relative flex items-center gap-4 overflow-hidden rounded-full bg-black px-12 py-8 font-mono text-xs uppercase tracking-widest text-white transition-transform duration-300 ease-out hover:scale-110 focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#4A70A9]"
                    style={{ transform: buttonTransform }}
                    type="button"
                    onClick={() => document.getElementById("store-downloads")?.scrollIntoView({ behavior: "smooth", block: "center" })}
                  >
                    <span className="relative z-10 transition-transform" style={{ transform: labelTransform }}>
                      {en ? "Download the app" : "Descarca aplicatia"}
                    </span>
                    <span className="material-symbols-outlined relative z-10 transition-transform group-hover:translate-x-2">
                      arrow_downward
                    </span>
                    <span className="absolute inset-0 translate-y-full bg-[#4A70A9] transition-transform duration-500 group-hover:translate-y-0" />
                  </button>
                </div>
                <div className="flex flex-col gap-2">
                  <span className="font-mono text-[10px] uppercase tracking-normal text-[#444748]/60">
                    {en ? "Scan for instant access" : "Scaneaza pentru acces instant"}
                  </span>
                  <div className="h-24 w-24 border border-[#c4c7c7] bg-[#eeeeee] p-2">
                    <img
                      className="h-full w-full grayscale transition-all duration-700 hover:grayscale-0"
                      src={images.qr}
                      alt={en ? "QR code to download PINLEND" : "Cod QR pentru descarcarea aplicatiei PINLEND"}
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
                    alt={en ? "Phone showing the PINLEND app" : "Telefon cu interfata aplicatiei PINLEND"}
                  />
                  <div className="absolute -right-20 -top-10 border border-[#c4c7c7]/20 bg-[#f9f9f9]/90 p-6 shadow-xl backdrop-blur-xl">
                    <div className="flex items-center gap-3">
                      <div className="flex h-10 w-10 items-center justify-center rounded-full bg-[#4A70A9] text-white">
                        <span className="material-symbols-outlined text-[20px]">verified</span>
                      </div>
                      <div className="flex flex-col">
                        <span className="font-mono text-[10px] uppercase opacity-60">{en ? "Verified member" : "Membru verificat"}</span>
                        <span className="text-base font-medium leading-6">9.2k online</span>
                      </div>
                    </div>
                  </div>
                  <div className="absolute -bottom-12 -left-24 hidden bg-black p-8 shadow-2xl lg:block">
                    <span className="font-display text-[40px] font-bold text-white">98%</span>
                    <p className="font-mono text-xs uppercase tracking-widest text-white/60">
                      {en ? "Trust rating" : "Rating incredere"}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </section>

          <section id="store-downloads" className="w-full scroll-mt-20 border-y border-[#c4c7c7]/10 bg-[#eeeeee] px-5 py-24 md:px-20">
            <div className="flex flex-col items-center justify-between gap-12 lg:flex-row">
              <div className="flex max-w-sm flex-col gap-4">
                <h3 className="text-[32px] font-medium leading-10 text-black">{en ? "Works across devices" : "Utilitate cross-platform"}</h3>
                <p className="text-base leading-6 text-[#444748]">
                  {en ? "Keep your listings in sync across devices. Optimized for iOS and Android." : "Sincronizează anunțurile tale intre dispozitive. Optimizat pentru iOS si Android."}
                </p>
              </div>
              <div className="flex flex-wrap justify-center gap-4">
                <StoreBadge store="apple" />
                <StoreBadge store="google" />
              </div>
            </div>
          </section>

        </div>
      </main>

      <PublicFooter />
    </>
  );
}
