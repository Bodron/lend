import LegalLayout from "@/components/LegalLayout";
import { useRouter } from "next/router";

export default function TermsAndConditions() {
  if (useRouter().locale === "en") return <LegalLayout title="Terms and conditions" eyebrow="Terms" updated="25 July 2026" description="The main rules for using PINLEND, including accounts, rentals, deposits, payments, responsibilities, and limitations.">
    <h2>1. Accepting the terms</h2><p>By using PINLEND, you accept these terms. If you disagree, do not use the service.</p>
    <h2>2. Eligibility</h2><p>You must be at least 18 and legally able to enter into contracts. We may require identity verification for rentals.</p>
    <h2>3. Your account</h2><p>You are responsible for the information you provide, your account security, and activity under your account.</p>
    <h2>4. Listings and rentals</h2><p>Owners must describe items accurately, post real photos, and hand over items in the stated condition. Renters must use items responsibly and return them on time.</p>
    <h2>5. Payments, deposits, and fees</h2><p>Payments, deposits, and refunds may be processed by third parties. PINLEND may charge fees and hold or release deposits under the rental terms.</p>
    <h2>6. Verification and safety</h2><p>We may refuse, suspend, or limit accounts when we detect fraud, safety risks, false information, or a breach of these terms.</p>
    <h2>7. Prohibited items</h2><p>Illegal or dangerous items, weapons, controlled substances, counterfeit goods, and items that violate laws or others’ rights are prohibited.</p>
    <h2>8. Damage and disputes</h2><p>Users should document handover and return. In a dispute, PINLEND may review evidence and decide on deposits, refunds, or account restrictions.</p>
    <h2>9. Intellectual property</h2><p>The PINLEND brand, design, text, and software belong to PINLEND or its licensors. You may not copy or use them without permission.</p>
    <h2>10. Limitation of liability</h2><p>The service is provided as is, to the extent permitted by law. We do not guarantee uninterrupted availability or that the service is error-free.</p>
    <h2>11. Ending access</h2><p>We may suspend or close your account if you breach these terms, the law, or our safety rules.</p>
    <h2>12. Contact</h2><p>For questions about the terms, write to <a href="mailto:support@pinfers.com">support@pinfers.com</a>.</p>
  </LegalLayout>;
  return (
    <LegalLayout
      title="Termeni si conditii"
      eyebrow="Terms"
      updated="25 iulie 2026"
      description="Regulile principale pentru folosirea PINLEND, inclusiv conturi, inchirieri, garantii, plati, responsabilitati si limitari."
    >
      <h2>1. Acceptarea termenilor</h2>
      <p>Prin folosirea PINLEND, accepti acesti termeni. Daca nu esti de acord, nu folosi serviciul.</p>

      <h2>2. Eligibilitate</h2>
      <p>Trebuie sa ai cel putin 18 ani si capacitatea legala de a incheia contracte. Putem cere verificarea identitatii pentru inchirieri.</p>

      <h2>3. Contul tau</h2>
      <p>Esti responsabil pentru informatiile introduse, securitatea contului si activitatea desfasurata prin contul tau.</p>

      <h2>4. Anunturi si inchirieri</h2>
      <p>Proprietarii trebuie sa descrie obiectele corect, sa publice fotografii reale si sa predea obiectele in starea declarata. Chiriasii trebuie sa foloseasca obiectele responsabil si sa le returneze la timp.</p>

      <h2>5. Plati, garantii si taxe</h2>
      <p>Platile, garantiile si rambursarile pot fi procesate prin furnizori terti. PINLEND poate retine comisioane si poate bloca sau elibera garantii conform conditiilor inchirierii.</p>

      <h2>6. Verificare si siguranta</h2>
      <p>Putem refuza, suspenda sau limita conturi atunci cand detectam frauda, risc de siguranta, informatii false sau incalcari ale termenilor.</p>

      <h2>7. Obiecte interzise</h2>
      <p>Nu sunt permise obiecte ilegale, periculoase, arme, substante controlate, bunuri contrafacute sau orice obiect care incalca legea ori drepturile altor persoane.</p>

      <h2>8. Daune si dispute</h2>
      <p>Utilizatorii trebuie sa documenteze predarea si returul. In caz de disputa, PINLEND poate analiza dovezile si poate lua decizii privind garantii, rambursari sau restrictii de cont.</p>

      <h2>9. Proprietate intelectuala</h2>
      <p>Brandul, designul, textele si software-ul PINLEND apartin PINLEND sau licentiatorilor sai. Nu ai voie sa le copiezi sau folosesti fara acord.</p>

      <h2>10. Limitarea raspunderii</h2>
      <p>Serviciul este oferit ca atare, in limitele permise de lege. Nu garantam disponibilitatea neintrerupta sau lipsa erorilor.</p>

      <h2>11. Incetarea accesului</h2>
      <p>Putem suspenda sau inchide contul daca incalci acesti termeni, legea sau regulile de siguranta ale platformei.</p>

      <h2>12. Contact</h2>
      <p>Pentru intrebari despre termeni, scrie la <a href="mailto:support@pinfers.com">support@pinfers.com</a>.</p>
    </LegalLayout>
  );
}
