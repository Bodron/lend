import LegalLayout from "@/components/LegalLayout";
import Link from "next/link";

export default function Support() {
  return (
    <LegalLayout
      title="Suport BorrowIt"
      eyebrow="Support"
      updated="25 iulie 2026"
      description="Pagina de suport pentru utilizatori, App Store review si Google Play. Gasesti aici contact, probleme frecvente si informatii despre cont."
    >
      <h2>Contact rapid</h2>
      <p>
        Pentru suport general: <a href="mailto:support@borrowit.app">support@borrowit.app</a>
      </p>
      <p>
        Pentru confidentialitate: <a href="mailto:privacy@borrowit.app">privacy@borrowit.app</a>
      </p>
      <p>
        Pentru termeni sau cereri legale: <a href="mailto:legal@borrowit.app">legal@borrowit.app</a>
      </p>

      <h2>Probleme frecvente</h2>
      <h3>Nu pot intra in cont</h3>
      <p>Verifica emailul, parola si codul primit prin SMS. Daca problema continua, contacteaza suportul cu emailul contului.</p>

      <h3>Vreau sa sterg contul</h3>
      <p>
        Foloseste pagina <Link href="/account-deletion">Stergere cont</Link> sau scrie la privacy@borrowit.app.
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
