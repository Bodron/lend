/* eslint-disable @next/next/no-img-element */
import Link from "next/link";
import { useState } from "react";

export default function ListingCard({ item, onCursorMove, onCursorLeave, t }) {
  const [transform, setTransform] = useState("perspective(1000px) rotateX(0deg) rotateY(0deg) scale(1)");

  function handleMouseMove(event) {
    const rect = event.currentTarget.getBoundingClientRect();
    const x = event.clientX - rect.left;
    const y = event.clientY - rect.top;
    const rotateX = ((y - rect.height / 2) / (rect.height / 2)) * -8;
    const rotateY = ((x - rect.width / 2) / (rect.width / 2)) * 8;
    setTransform(`perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) scale(1.02)`);
    onCursorMove({ x: event.clientX, y: event.clientY, visible: true });
  }

  function handleMouseLeave() {
    setTransform("perspective(1000px) rotateX(0deg) rotateY(0deg) scale(1)");
    onCursorLeave();
  }

  return <article className={`listing-card group relative ${item.offset}`} onMouseLeave={handleMouseLeave} onMouseMove={handleMouseMove}>
    <Link aria-label={`${t.detailsLabel} ${item.title}`} className="block transition-all duration-500 ease-out" href={`/anunt/${encodeURIComponent(item.slug)}`} style={{ transform, transformStyle: "preserve-3d" }}>
      <div className={`relative overflow-hidden rounded-xl bg-[#eeeeee] ${item.aspect}`}>
        {item.image ? <img alt={item.title} className="h-full w-full object-cover transition-transform duration-700 group-hover:scale-110" decoding="async" loading="lazy" src={item.image} /> : <div className="flex h-full w-full items-center justify-center font-mono text-xs uppercase tracking-widest text-[#444748]">{t.noImage}</div>}
        <div className="pointer-events-none absolute inset-0 flex items-center justify-center bg-black/25 opacity-0 transition-opacity duration-500 group-hover:opacity-100">
          <span className="border border-white px-4 py-2 font-mono text-xs uppercase tracking-widest text-white backdrop-blur-sm">{t.details}</span>
        </div>
      </div>
      <div className="mt-6">
        <div className="mb-2 flex items-start justify-between gap-4">
          <h3 className="text-2xl font-medium uppercase leading-8 tracking-normal text-black">{item.title}</h3>
          <span className="shrink-0 pt-2 font-mono text-xs uppercase tracking-widest text-[#444748]">{item.price}</span>
        </div>
        <p className="mb-2 flex items-center gap-1 font-mono text-[11px] uppercase tracking-wider text-[#30578F]"><span aria-hidden="true" className="material-symbols-outlined text-[16px]">location_on</span>{item.city || t.unknownCity}</p>
        <p className="line-clamp-3 text-base leading-6 text-[#444748]/80">{item.text}</p>
      </div>
    </Link>
  </article>;
}
