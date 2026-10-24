import Image from "next/image";
import { useRouter } from "next/router";
import StoreBadge from "./StoreBadge";

const content = {
  ro: {
    eyebrow: "PINLEND PE TELEFON",
    title: "PINLEND pe telefon, mai simplu.",
    description: "Pentru o experiență mai plăcută pe telefon, descarcă aplicația PINLEND. Acolo poți face și returul prin scanarea codului QR.",
    note: "Pe desktop poți folosi în continuare site-ul.",
  },
  en: {
    eyebrow: "PINLEND ON YOUR PHONE",
    title: "PINLEND works better in the app.",
    description: "For a smoother experience on your phone, download the PINLEND app. You can also complete returns by scanning the QR code there.",
    note: "You can still use the website on desktop.",
  },
};

export default function MobileAppGate() {
  const { locale } = useRouter();
  const copy = content[locale] || content.ro;

  return (
    <main className="mobile-app-gate">
      <div className="mobile-app-gate__content">
        <Image alt="PINLEND" className="mobile-app-gate__logo" height={42} priority src="/logo.svg" width={196} />
        <span className="mobile-app-gate__eyebrow">{copy.eyebrow}</span>
        <h1>{copy.title}</h1>
        <p>{copy.description}</p>
        <div className="mobile-app-gate__badges">
          <StoreBadge compact store="apple" />
          <StoreBadge compact store="google" />
        </div>
        <p className="mobile-app-gate__note">{copy.note}</p>
      </div>
    </main>
  );
}
