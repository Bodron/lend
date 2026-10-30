import LegalLayout from "@/components/LegalLayout";
import { useRouter } from "next/router";

export default function CookiePolicy() {
  if (useRouter().locale === "en") return <LegalLayout title="Cookie policy" eyebrow="Cookies" updated="25 July 2026" description="How PINLEND may use cookies and similar technologies on this site.">
    <h2>1. What cookies are</h2>
    <p>Cookies are small files stored in your browser for functionality, security, preferences, and performance measurement.</p>
    <h2>2. Types of cookies</h2>
    <ul>
      <li>Strictly necessary: site operation and security;</li>
      <li>Preferences: language and display settings;</li>
      <li>Analytics: traffic measurement and product improvement;</li>
      <li>Marketing: only if enabled and you have consented where required.</li>
    </ul>
    <h2>3. How to control them</h2>
    <p>You can block or delete cookies in your browser settings. Some features may be limited if you disable strictly necessary cookies.</p>
    <h2>4. Contact</h2>
    <p>For questions about cookies, write to <a href="mailto:support@pinfers.com">support@pinfers.com</a>.</p>
  </LegalLayout>;
  return (
    <LegalLayout
      title="Politica de cookies"
      eyebrow="Cookies"
      updated="25 iulie 2026"
      description="Aceasta pagina explica modul in care PINLEND poate folosi cookies si tehnologii similare pe site."
    >
      <h2>1. Ce sunt cookies</h2>
      <p>Cookies sunt fisiere mici salvate in browser pentru functionalitate, securitate, preferinte si masurarea performantei.</p>

      <h2>2. Tipuri de cookies</h2>
      <ul>
        <li>strict necesare: functionarea site-ului si securitate;</li>
        <li>preferinte: limba si setari de afisare;</li>
        <li>analytics: masurarea traficului si imbunatatirea produsului;</li>
        <li>marketing: doar daca vor fi activate si daca ai consimtit, unde este necesar.</li>
      </ul>

      <h2>3. Cum le controlezi</h2>
      <p>Poti bloca sau sterge cookies din setarile browserului. Unele functionalitati pot functiona limitat daca dezactivezi cookies strict necesare.</p>

      <h2>4. Contact</h2>
      <p>Pentru intrebari despre cookies, scrie la <a href="mailto:support@pinfers.com">support@pinfers.com</a>.</p>
    </LegalLayout>
  );
}
