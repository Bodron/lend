import LegalLayout from "@/components/LegalLayout";

export default function PrivacyChoices() {
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
        Scrie la <a href="mailto:privacy@borrowit.app?subject=Cerere%20date%20personale%20BorrowIt">privacy@borrowit.app</a> si include emailul sau numarul de telefon asociat contului.
      </p>

      <h2>3. Verificarea cererii</h2>
      <p>Pentru siguranta, putem cere informatii suplimentare pentru a confirma ca solicitarea vine de la titularul contului.</p>

      <h2>4. Raspuns</h2>
      <p>Raspundem in termenele cerute de legislatia aplicabila. Pentru utilizatorii din UE, drepturile sunt tratate conform GDPR.</p>
    </LegalLayout>
  );
}
