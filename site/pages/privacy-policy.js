import LegalLayout from "@/components/LegalLayout";
import Link from "next/link";

export default function PrivacyPolicy() {
  return (
    <LegalLayout
      title="Politica de confidentialitate"
      eyebrow="Privacy Policy"
      updated="25 iulie 2026"
      description="Explicam ce date colecteaza BorrowIt, cum le folosim, cu cine le partajam si ce drepturi ai asupra datelor tale."
    >
      <h2>1. Cine suntem</h2>
      <p>
        BorrowIt este o platforma pentru inchirierea de obiecte intre utilizatori. Pentru intrebari despre datele tale, ne poti contacta la{" "}
        <a href="mailto:privacy@borrowit.app">privacy@borrowit.app</a>.
      </p>

      <h2>2. Date pe care le colectam</h2>
      <p>Putem colecta urmatoarele categorii de date, in functie de modul in care folosesti aplicatia sau site-ul:</p>
      <ul>
        <li>date de cont: nume, email, parola, limba, preferinte;</li>
        <li>date de contact: numar de telefon si confirmari SMS;</li>
        <li>date de identitate: documente, selfie, rezultat verificare si status KYC, procesate prin furnizori specializati precum Stripe Identity;</li>
        <li>date de plata: identificatori de plata, garantii, rambursari si tranzactii, procesate prin furnizori de plati;</li>
        <li>date despre anunturi: fotografii, descrieri, pret, locatie aproximativa si disponibilitate;</li>
        <li>date tehnice: dispozitiv, IP, loguri, crash reports, analytics si setari cookies;</li>
        <li>comunicari: mesaje de suport, notificari si conversatii legate de inchirieri.</li>
      </ul>

      <h2>3. Cum folosim datele</h2>
      <p>Folosim datele pentru a furniza serviciul, a verifica identitatea, a preveni frauda, a procesa plati si garantii, a imbunatati aplicatia, a trimite notificari si a respecta obligatiile legale.</p>

      <h2>4. Furnizori si parteneri</h2>
      <p>
        Putem partaja date cu procesatori precum furnizori de plati, verificare identitate, SMS, hosting, analytics, customer support si autoritati publice atunci cand legea o cere.
      </p>

      <h2>5. Date de identitate</h2>
      <p>
        Documentele de identitate sunt folosite pentru verificare si securitate. Nu le folosim pentru marketing. Accesul la aceste date este limitat si depinde de furnizorul de verificare si de setarile contului nostru operational.
      </p>

      <h2>6. Pastrarea datelor</h2>
      <p>
        Pastram datele cat timp contul este activ si apoi doar cat este necesar pentru obligatii legale, litigii, prevenirea fraudei, contabilitate si siguranta platformei.
      </p>

      <h2>7. Drepturile tale</h2>
      <p>
        In functie de jurisdictie, poti cere acces, rectificare, stergere, restrictionare, portabilitate sau opozitie. Pentru cereri, foloseste pagina{" "}
        <Link href="/privacy-choices">Optiuni de confidentialitate</Link>.
      </p>

      <h2>8. Minori</h2>
      <p>BorrowIt nu este destinat persoanelor sub 18 ani. Daca aflam ca am colectat date de la un minor, vom lua masuri pentru stergere.</p>

      <h2>9. Transferuri internationale</h2>
      <p>Datele pot fi procesate in UE, SUA sau alte tari, prin furnizori cu masuri contractuale si tehnice adecvate.</p>

      <h2>10. Modificari</h2>
      <p>Putem actualiza aceasta politica. Data ultimei actualizari va fi afisata pe pagina.</p>
    </LegalLayout>
  );
}
