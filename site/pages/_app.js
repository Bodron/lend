import "@/styles/globals.css";
import "maplibre-gl/dist/maplibre-gl.css";
import { useEffect, useState } from "react";
import { useRouter } from "next/router";
import BrandLoader from "@/components/BrandLoader";
import { Toaster } from "@/components/ui/sonner";
import { ConfirmActionProvider } from "@/components/ConfirmActionProvider";
import { AccountProfileProvider } from "@/components/AccountProfileProvider";
import MobileAppGate from "@/components/MobileAppGate";

export default function App({ Component, pageProps }) {
  const router = useRouter();
  const [loadingRoute, setLoadingRoute] = useState(false);

  useEffect(() => {
    let timer;
    const start = (url, { shallow }) => {
      if (shallow || url === router.asPath) return;
      window.clearTimeout(timer);
      timer = window.setTimeout(() => setLoadingRoute(true), 150);
    };
    const stop = () => {
      window.clearTimeout(timer);
      setLoadingRoute(false);
    };
    router.events.on("routeChangeStart", start);
    router.events.on("routeChangeComplete", stop);
    router.events.on("routeChangeError", stop);
    return () => {
      window.clearTimeout(timer);
      router.events.off("routeChangeStart", start);
      router.events.off("routeChangeComplete", stop);
      router.events.off("routeChangeError", stop);
    };
  }, [router]);

  return <>
    <Toaster duration={5000} position="top-right" visibleToasts={3} />
    <MobileAppGate />
    <div className="desktop-site">
      <AccountProfileProvider><ConfirmActionProvider><Component {...pageProps} /></ConfirmActionProvider></AccountProfileProvider>
      {loadingRoute && <BrandLoader label="Se deschide pagina..." overlay />}
    </div>
  </>;
}
