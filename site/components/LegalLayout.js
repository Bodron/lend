import Head from "next/head";
import Link from "next/link";
import { useRouter } from "next/router";
import PublicHeader from "./PublicHeader";
import PublicFooter from "./PublicFooter";

export default function LegalLayout({ title, description, eyebrow, updated, children }) {
  const { locale, pathname } = useRouter();
  const en = locale === "en";

  return (
    <>
      <Head>
        <title>{`${title} | PINLEND`}</title>
        <meta name="description" content={description} />
      </Head>

      <PublicHeader current={pathname} />

      <main className="bg-[#f9f9f9] px-5 pb-24 pt-36 md:px-20 md:pb-40 md:pt-48">
        <section className="mx-auto max-w-6xl">
          <p className="mb-6 flex items-center gap-4 font-mono text-xs uppercase tracking-[0.3em] text-[#4A70A9]">
            <span className="h-px w-12 bg-[#4A70A9]" />
            {eyebrow}
          </p>
          <h1 className="download-display-2xl max-w-5xl font-display font-extrabold text-black">
            {title}
          </h1>
          <p className="mt-10 max-w-2xl text-xl leading-8 text-[#444748]">{description}</p>
          <p className="mt-6 font-mono text-xs uppercase tracking-widest text-black/40">
            {en ? "Last updated" : "Ultima actualizare"}: {en && updated === "25 iulie 2026" ? "25 July 2026" : updated}
          </p>
        </section>

        <section className="mx-auto mt-20 grid max-w-6xl grid-cols-1 gap-12 lg:grid-cols-[260px_1fr]">
          <aside className="h-fit border-l border-black/10 pl-6 lg:sticky lg:top-28">
            <p className="mb-5 font-mono text-xs uppercase tracking-widest text-black/40">{en ? "Useful pages" : "Pagini utile"}</p>
            <nav className="flex flex-col gap-3 text-base leading-6">
              <Link href="/privacy-policy">{en ? "Privacy policy" : "Politica de confidentialitate"}</Link>
              <Link href="/privacy-choices">{en ? "Privacy choices" : "Optiuni de confidentialitate"}</Link>
              <Link href="/terms-and-conditions">{en ? "Terms and conditions" : "Termeni si conditii"}</Link>
              <Link href="/cookie-policy">{en ? "Cookie policy" : "Politica de cookies"}</Link>
              <Link href="/account-deletion">{en ? "Delete account" : "Stergere cont"}</Link>
              <Link href="/support">{en ? "Support" : "Suport"}</Link>
            </nav>
          </aside>
          <div className="legal-content min-w-0">{children}</div>
        </section>
      </main>

      <PublicFooter />
    </>
  );
}
