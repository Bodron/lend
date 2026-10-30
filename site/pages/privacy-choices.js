import LegalLayout from "@/components/LegalLayout";
import { useRouter } from "next/router";

export default function PrivacyChoices() {
  if (useRouter().locale === "en") return <LegalLayout title="Privacy choices" eyebrow="Data rights" updated="25 July 2026" description="Request access, correction, export, restriction, or deletion of your data.">
    <h2>1. Available requests</h2>
    <ul><li>Access to the data we hold about you;</li><li>Correction of inaccurate data;</li><li>Export in a portable format, where applicable;</li><li>Restriction of certain processing;</li><li>Objection to processing where the law allows;</li><li>Deletion of data or your account.</li></ul>
    <h2>2. How to submit a request</h2>
    <p>Write to <a href="mailto:support@pinfers.com?subject=PINLEND%20personal%20data%20request">support@pinfers.com</a> and include the email address or phone number linked to your account.</p>
    <h2>3. Verifying your request</h2>
    <p>For security, we may ask for additional information to confirm that the request comes from the account holder.</p>
    <h2>4. Response</h2>
    <p>We respond within the periods required by applicable law. For EU users, these rights are handled under the GDPR.</p>
  </LegalLayout>;
  return (
    <LegalLayout
      title="Optiuni de confidentialitate"
      eyebrow="Data rights"
      updated="25 iulie 2026"
      description="Foloseste aceasta pagina pentru a solicita acces, rectificare, export, restrictionare sau stergere a datelor tale."
    >
      <h2>1. Cereri disponibile</h2>
      <ul>
        <li>acces la datele pe care le avem despre tine;</li>
        <li>corectarea datelor incorecte;</li>
        <li>exportul datelor intr-un format portabil, acolo unde este aplicabil;</li>
        <li>restrictionarea anumitor prelucrari;</li>
        <li>opozitie la prelucrare, unde legea permite;</li>
        <li>stergerea datelor sau a contului.</li>
      </ul>

      <h2>2. Cum trimiti o cerere</h2>
      <p>
        Scrie la <a href="mailto:support@pinfers.com?subject=Cerere%20date%20personale%20PINLEND">support@pinfers.com</a> si include emailul sau numarul de telefon asociat contului.
      </p>

      <h2>3. Verificarea cererii</h2>
      <p>Pentru siguranta, putem cere informatii suplimentare pentru a confirma ca solicitarea vine de la titularul contului.</p>

      <h2>4. Raspuns</h2>
      <p>Raspundem in termenele cerute de legislatia aplicabila. Pentru utilizatorii din UE, drepturile sunt tratate conform GDPR.</p>
    </LegalLayout>
  );
}
