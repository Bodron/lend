import LegalLayout from "@/components/LegalLayout";

export default function AccountDeletion() {
  return (
    <LegalLayout
      title="Stergere cont"
      eyebrow="Account deletion"
      updated="25 iulie 2026"
      description="Aici poti solicita stergerea contului BorrowIt si a datelor asociate, conform cerintelor Google Play si regulilor de confidentialitate."
    >
      <h2>1. Cum soliciti stergerea</h2>
      <p>
        Trimite o cerere la <a href="mailto:privacy@borrowit.app?subject=Cerere%20stergere%20cont%20BorrowIt">privacy@borrowit.app</a> de pe adresa asociata contului tau sau include numarul de telefon folosit in aplicatie.
      </p>
      <p>
        Include in mesaj: numele, emailul contului, numarul de telefon si mentiunea clara „Solicit stergerea contului BorrowIt”.
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
