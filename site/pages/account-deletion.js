import LegalLayout from "@/components/LegalLayout";
import { useRouter } from "next/router";

export default function AccountDeletion() {
  if (useRouter().locale === "en") return <LegalLayout title="Delete your account" eyebrow="Account deletion" updated="25 July 2026" description="Request deletion of your PINLEND account and associated data.">
    <h2>1. How to request deletion</h2>
    <p>Send a request to <a href="mailto:support@pinfers.com?subject=PINLEND%20account%20deletion%20request">support@pinfers.com</a> from the email address linked to your account, or include the phone number used in the app.</p>
    <p>Include your name, account email, phone number, and a clear request to delete your PINLEND account.</p>
    <h2>2. What we delete</h2>
    <ul><li>Your account profile and preferences;</li><li>Inactive listings and their photos;</li><li>Support messages that we are not legally required to retain;</li><li>Tokens, sessions, and operational data no longer needed.</li></ul>
    <h2>3. What we may retain temporarily</h2>
    <p>We may retain some data for legal obligations, accounting, active disputes, fraud prevention, chargebacks, user safety, or requests from authorities.</p>
    <h2>4. Processing time</h2>
    <p>We normally confirm and process the request within 30 days, unless the law requires or permits a longer period.</p>
    <h2>5. Deletion in the app</h2>
    <p>If the app offers account deletion in settings, you can use that flow. This page remains available as an alternative web method.</p>
  </LegalLayout>;
  return (
    <LegalLayout
      title="Stergere cont"
      eyebrow="Account deletion"
      updated="25 iulie 2026"
      description="Aici poti solicita stergerea contului PINLEND si a datelor asociate, conform cerintelor Google Play si regulilor de confidentialitate."
    >
      <h2>1. Cum soliciti stergerea</h2>
      <p>
        Trimite o cerere la <a href="mailto:support@pinfers.com?subject=Cerere%20stergere%20cont%20PINLEND">support@pinfers.com</a> de pe adresa asociata contului tau sau include numarul de telefon folosit in aplicatie.
      </p>
      <p>
        Include in mesaj: numele, emailul contului, numarul de telefon si mentiunea clara „Solicit stergerea contului PINLEND”.
      </p>

      <h2>2. Ce stergem</h2>
      <ul>
        <li>profilul contului si preferintele;</li>
        <li>anunturile inactive si fotografiile asociate;</li>
        <li>mesajele de suport care nu trebuie pastrate legal;</li>
        <li>tokenuri, sesiuni si date operationale care nu mai sunt necesare.</li>
      </ul>

      <h2>3. Ce putem pastra temporar</h2>
      <p>
        Putem pastra unele date pentru obligatii legale, contabilitate, dispute active, prevenirea fraudei, chargeback-uri, siguranta utilizatorilor sau cereri ale autoritatilor.
      </p>

      <h2>4. Termen de procesare</h2>
      <p>Vom confirma cererea si o vom procesa in mod normal in maximum 30 de zile, cu exceptia cazurilor in care legea cere sau permite o perioada mai lunga.</p>

      <h2>5. Stergere din aplicatie</h2>
      <p>Daca aplicatia are optiune de stergere cont in setari, foloseste acel flux. Aceasta pagina ramane disponibila ca metoda web alternativa.</p>
    </LegalLayout>
  );
}
