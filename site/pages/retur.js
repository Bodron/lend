/* eslint-disable @next/next/no-img-element */
import Head from "next/head";
import Link from "next/link";
import { useEffect, useState } from "react";
import QRCode from "qrcode";
import AppHeader from "../components/AppHeader";
import StoreBadge from "../components/StoreBadge";

export default function ReturnPage() {
  const [downloadQr, setDownloadQr] = useState("");

  useEffect(() => {
    QRCode.toDataURL(`${window.location.origin}/download`, { width: 240, margin: 2 })
      .then(setDownloadQr)
      .catch(() => setDownloadQr(""));
  }, []);

  return <>
    <Head><title>Retur în aplicație | PINLEND</title></Head>
    <AppHeader />
    <main className="mx-auto max-w-5xl px-5 py-12 md:px-8">
      <p className="font-mono text-xs uppercase tracking-widest text-[#30578F]">Închirieri</p>
      <h1 className="mt-3 font-display text-4xl font-extrabold">Returul se face din aplicație</h1>
      <p className="mt-4 max-w-2xl text-lg leading-7 text-[#626977]">
        Pentru returul cu cod QR, atât chiriașul, cât și proprietarul folosesc aplicația PINLEND pe telefon. Intră cu același cont ca pe site.
      </p>

      <div className="mt-10 grid gap-6 md:grid-cols-2">
        <section className="account-card">
          <span aria-hidden="true" className="material-symbols-outlined text-4xl text-[#30578F]">qr_code_2</span>
          <h2 className="mt-4 text-xl font-extrabold">Dacă ai închiriat obiectul</h2>
          <p className="mt-3 leading-7 text-[#626977]">Deschide închirierea în aplicație și afișează codul QR de retur proprietarului.</p>
        </section>
        <section className="account-card">
          <span aria-hidden="true" className="material-symbols-outlined text-4xl text-[#30578F]">qr_code_scanner</span>
          <h2 className="mt-4 text-xl font-extrabold">Dacă ești proprietarul</h2>
          <p className="mt-3 leading-7 text-[#626977]">Deschide închirierile în aplicație, scanează codul QR și confirmă că ai primit obiectul.</p>
        </section>
      </div>

      <section className="mt-8 flex flex-col items-center gap-8 rounded-[24px] bg-[#E7F0FD] p-6 md:flex-row md:justify-between md:p-10">
        <div className="max-w-lg text-center md:text-left">
          <h2 className="text-2xl font-extrabold">Descarcă aplicația PINLEND</h2>
          <p className="mt-3 text-[#434750]">Alege magazinul telefonului tău sau scanează codul alăturat ca să deschizi pagina de descărcare pe telefon.</p>
          <div className="mt-5 flex flex-wrap justify-center gap-4 md:justify-start">
            <StoreBadge compact store="apple" />
            <StoreBadge compact store="google" />
          </div>
        </div>
        {downloadQr && <img alt="Scanează pentru a deschide pagina de descărcare PINLEND pe telefon" className="h-40 w-40 shrink-0 rounded-xl bg-white p-2" height="160" src={downloadQr} width="160" />}
      </section>
      <Link className="mt-8 inline-block text-sm font-bold text-[#30578F] underline" href="/account">Înapoi la închirierile mele</Link>
    </main>
  </>;
}
