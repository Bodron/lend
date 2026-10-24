/* eslint-disable @next/next/no-img-element */
import { toast } from "sonner";

const storeLinks = {
  apple: process.env.NEXT_PUBLIC_APP_STORE_URL,
  google: process.env.NEXT_PUBLIC_GOOGLE_PLAY_URL,
};

export default function StoreBadge({ store, compact = false }) {
  const isApple = store === "apple";
  const name = isApple ? "App Store" : "Google Play";
  const image = (
    <span className={compact ? "relative block h-14 w-44 overflow-hidden" : "block"}>
      <img
        alt=""
        className={compact
          ? isApple ? "absolute inset-0 h-14 w-44" : "absolute -left-[13px] -top-[14px] h-[84px] w-[202px] max-w-none"
          : isApple ? "h-14 w-auto" : "h-[84px] w-auto"}
        height={isApple ? 56 : 84}
        src={isApple ? "/store-badges/app-store.svg" : "/store-badges/google-play.png"}
        width={isApple ? 168 : 217}
      />
    </span>
  );
  const className = `inline-flex items-center justify-center rounded-md focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#4A70A9] ${compact ? "h-14 w-44" : "min-h-16"}`;
  const url = storeLinks[store]?.trim();

  return url ? (
    <a aria-label={`Descarcă PINLEND din ${name}`} className={className} href={url} rel="noopener noreferrer" target="_blank">
      {image}
    </a>
  ) : (
    <button aria-label={`PINLEND pentru ${name} va fi disponibil în curând`} className={className} onClick={() => toast.info(`Linkul PINLEND pentru ${name} va fi disponibil în curând.`)} type="button">
      {image}
    </button>
  );
}
