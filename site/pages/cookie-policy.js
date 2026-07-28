import LegalLayout from "@/components/LegalLayout";

export default function CookiePolicy() {
  return (
    <LegalLayout
      title="Politica de cookies"
      eyebrow="Cookies"
      updated="25 iulie 2026"
      description="Aceasta pagina explica modul in care BorrowIt poate folosi cookies si tehnologii similare pe site."
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
      <p>Pentru intrebari despre cookies, scrie la <a href="mailto:privacy@borrowit.app">privacy@borrowit.app</a>.</p>
    </LegalLayout>
  );
}
