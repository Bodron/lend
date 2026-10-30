import LegalLayout from "@/components/LegalLayout";
import Link from "next/link";
import { useRouter } from "next/router";

export default function Support() {
  if (useRouter().locale === "en") return <LegalLayout title="PINLEND support" eyebrow="Support" updated="25 July 2026" description="Find contact details, answers to common issues, and account information.">
    <h2>Quick contact</h2>
    <p>General support: <a href="mailto:support@pinfers.com">support@pinfers.com</a></p>
    <p>Privacy: <a href="mailto:support@pinfers.com">support@pinfers.com</a></p>
    <p>Terms or legal requests: <a href="mailto:support@pinfers.com">support@pinfers.com</a></p>
    <h2>Common issues</h2>
    <h3>I cannot sign in</h3><p>Check your email and password. If the problem continues, contact support using your account email.</p>
    <h3>I want to delete my account</h3><p>Use the <Link href="/account-deletion">account deletion page</Link> or write to support@pinfers.com.</p>
    <h3>I have a problem with a rental</h3><p>Keep your photos, messages, handover record, and booking details. Send the booking number to support.</p>
    <h3>Identity verification does not work</h3><p>Make sure your document is clear and valid and that your details match it. If verification remains stuck, contact support.</p>
    <h2>Response time</h2><p>We aim to respond within 1–3 business days, depending on the request.</p>
  </LegalLayout>;
  return (
    <LegalLayout
      title="Suport PINLEND"
      eyebrow="Support"
      updated="25 iulie 2026"
      description="Pagina de suport pentru utilizatori, App Store review si Google Play. Gasesti aici contact, probleme frecvente si informatii despre cont."
    >
      <h2>Contact rapid</h2>
      <p>
        Pentru suport general: <a href="mailto:support@pinfers.com">support@pinfers.com</a>
      </p>
      <p>
        Pentru confidentialitate: <a href="mailto:support@pinfers.com">support@pinfers.com</a>
      </p>
      <p>
        Pentru termeni sau cereri legale: <a href="mailto:support@pinfers.com">support@pinfers.com</a>
      </p>

      <h2>Probleme frecvente</h2>
      <h3>Nu pot intra in cont</h3>
      <p>Verifica emailul si parola. Daca problema continua, contacteaza suportul cu emailul contului.</p>

      <h3>Vreau sa sterg contul</h3>
      <p>
        Foloseste pagina <Link href="/account-deletion">Stergere cont</Link> sau scrie la support@pinfers.com.
      </p>

      <h3>Am o problema cu o inchiriere</h3>
      <p>Pastreaza fotografiile, mesajele, dovada predarii si detaliile rezervarii. Trimite numarul rezervarii catre suport.</p>

      <h3>Verificarea identitatii nu functioneaza</h3>
      <p>Asigura-te ca documentul este clar, valid si ca datele introduse coincid cu documentul. Daca verificarea ramane blocata, contacteaza suportul.</p>

      <h2>Timp de raspuns</h2>
      <p>Incercam sa raspundem in 1-3 zile lucratoare, in functie de complexitatea cererii.</p>
    </LegalLayout>
  );
}
