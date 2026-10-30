import LegalLayout from "@/components/LegalLayout";
import Link from "next/link";
import { useRouter } from "next/router";

export default function PrivacyPolicy() {
  if (useRouter().locale === "en") return <LegalLayout title="Privacy policy" eyebrow="Privacy Policy" updated="25 July 2026" description="What data PINLEND collects, how we use and share it, and your rights over it.">
    <h2>1. Who we are</h2><p>PINLEND is a platform for renting items between users. For questions about your data, contact us at <a href="mailto:support@pinfers.com">support@pinfers.com</a>.</p>
    <h2>2. Data we collect</h2><p>Depending on how you use the app or website, we may collect:</p>
    <ul>
      <li>Account data: name, email, password, language, and preferences;</li>
      <li>Contact data: phone number;</li>
      <li>Identity data: documents, selfie, verification result, and KYC status, processed by specialist providers such as Stripe Identity;</li>
      <li>Payment data: payment identifiers, deposits, refunds, and transactions, processed by payment providers;</li>
      <li>Listing data: photos, descriptions, price, approximate location, and availability;</li>
      <li>Technical data: device, IP address, logs, crash reports, analytics, and cookie settings;</li>
      <li>Communications: support messages, notifications, and rental conversations.</li>
    </ul>
    <h2>3. How we use data</h2><p>We use data to provide the service, verify identity, prevent fraud, process payments and deposits, improve the app, send notifications, and meet legal obligations.</p>
    <h2>4. Providers and partners</h2><p>We may share data with processors such as payment, identity verification, hosting, analytics, and customer support providers, and with public authorities when required by law.</p>
    <h2>5. Identity data</h2><p>Identity documents are used for verification and security, not marketing. Access is limited and depends on the verification provider and our operational account settings.</p>
    <h2>6. Data retention</h2><p>We keep data while your account is active and afterwards only as needed for legal obligations, disputes, fraud prevention, accounting, and platform safety.</p>
    <h2>7. Your rights</h2><p>Depending on your jurisdiction, you may request access, correction, deletion, restriction, portability, or objection. Use our <Link href="/privacy-choices">privacy choices page</Link> to make a request.</p>
    <h2>8. Minors</h2><p>PINLEND is not intended for people under 18. If we learn that we collected data from a minor, we will take steps to delete it.</p>
    <h2>9. International transfers</h2><p>Data may be processed in the EU, US, or other countries through providers with appropriate contractual and technical measures.</p>
    <h2>10. Changes</h2><p>We may update this policy. The date of the latest update will be shown on this page.</p>
  </LegalLayout>;
  return (
    <LegalLayout
      title="Politica de confidentialitate"
      eyebrow="Privacy Policy"
      updated="25 iulie 2026"
      description="Explicam ce date colecteaza PINLEND, cum le folosim, cu cine le partajam si ce drepturi ai asupra datelor tale."
    >
      <h2>1. Cine suntem</h2>
      <p>
        PINLEND este o platforma pentru inchirierea de obiecte intre utilizatori. Pentru intrebari despre datele tale, ne poti contacta la{" "}
        <a href="mailto:support@pinfers.com">support@pinfers.com</a>.
      </p>

      <h2>2. Date pe care le colectam</h2>
      <p>Putem colecta urmatoarele categorii de date, in functie de modul in care folosesti aplicatia sau site-ul:</p>
      <ul>
        <li>date de cont: nume, email, parola, limba, preferinte;</li>
        <li>date de contact: numar de telefon;</li>
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
        Putem partaja date cu procesatori precum furnizori de plati, verificare identitate, hosting, analytics, customer support si autoritati publice atunci cand legea o cere.
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
      <p>PINLEND nu este destinat persoanelor sub 18 ani. Daca aflam ca am colectat date de la un minor, vom lua masuri pentru stergere.</p>

      <h2>9. Transferuri internationale</h2>
      <p>Datele pot fi procesate in UE, SUA sau alte tari, prin furnizori cu masuri contractuale si tehnice adecvate.</p>

      <h2>10. Modificari</h2>
      <p>Putem actualiza aceasta politica. Data ultimei actualizari va fi afisata pe pagina.</p>
    </LegalLayout>
  );
}
