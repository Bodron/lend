/* eslint-disable @next/next/no-img-element */
import Head from "next/head";
import Link from "next/link";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import AppHeader from "../components/AppHeader";
import BrandLoader from "../components/BrandLoader";
import { favoriteIds, setFavorite } from "../lib/favorites";
import { getPublicProducts } from "../lib/publicProductsServer";
import { useToastError } from "../lib/useToastError";

export async function getServerSideProps() {
  try {
    return { props: { products: await getPublicProducts() } };
  } catch { return { props: { products: [] } }; }
}

export default function Favorites({ products }) {
  const router = useRouter();
  const [ids, setIds] = useState([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState("");
  const [reloadKey, setReloadKey] = useState(0);
  const [, setError] = useToastError();
  useEffect(() => {
    let active = true;
    const update = () => {
      setLoading(true);
      setLoadError("");
      return favoriteIds().then((next) => { if (active) setIds(next); }).catch((cause) => {
      if (!active) return;
      if (cause.status === 401) router.replace(`/account?returnTo=${encodeURIComponent("/favorite")}`);
      else setLoadError(cause.status === 404 ? "Serviciul de favorite nu este disponibil momentan." : cause.message);
      }).finally(() => { if (active) setLoading(false); });
    };
    update();
    window.addEventListener("pinlend:favorites", update);
    return () => { active = false; window.removeEventListener("pinlend:favorites", update); };
  }, [router, reloadKey]);
  async function remove(id) {
    setError("");
    try {
      await setFavorite(id, false);
      setIds((current) => current.filter((item) => item !== id));
    } catch (cause) { setError(cause.message); }
  }
  const saved = products.filter((item) => ids.includes(String(item._id || item.id)));
  return <>
    <Head><title>Favorite | PINLEND</title></Head>
    <AppHeader />
    <main className="mx-auto max-w-7xl px-5 py-12 md:px-8"><p className="font-mono text-xs uppercase tracking-widest text-[#30578F]">Colecția ta</p><h1 className="mt-3 font-display text-4xl font-extrabold">Favorite</h1><p className="mt-3 text-[#626977]">Anunțurile salvate în contul tău, pe site și în aplicație.</p>
      
      {loading ? <BrandLoader className="mt-8 py-12" label="Se încarcă favoritele..." /> : loadError ? <div className="account-card mt-8" role="alert"><p>{loadError}</p><button className="account-button mt-5" onClick={() => setReloadKey((key) => key + 1)} type="button">Încearcă din nou</button></div> : saved.length === 0 ? <div className="account-card mt-8"><p>Nu ai anunțuri salvate.</p><Link className="account-button mt-5 inline-block" href="/">Descoperă anunțuri</Link></div> : <div className="mt-8 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">{saved.map((item) => <article className="overflow-hidden rounded-2xl bg-white shadow-sm" key={item._id || item.id}><Link href={`/anunt/${encodeURIComponent(item.slug)}`}>{item.images?.[0]?.url ? <img alt={item.title} className="aspect-[4/3] w-full object-cover" src={item.images[0].url} /> : <div className="flex aspect-[4/3] items-center justify-center bg-[#E7F0FD]">Fără imagine</div>}</Link><div className="p-5"><Link className="text-xl font-extrabold hover:text-[#30578F]" href={`/anunt/${encodeURIComponent(item.slug)}`}>{item.title}</Link><p className="mt-2 text-sm text-[#626977]">{item.city} · {item.pricePerDay} RON/zi</p><button className="mt-4 text-sm font-bold text-red-700" onClick={() => remove(String(item._id || item.id))} type="button">Elimină din favorite</button></div></article>)}</div>}
    </main>
  </>;
}
