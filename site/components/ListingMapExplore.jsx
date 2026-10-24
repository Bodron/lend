/* eslint-disable @next/next/no-img-element */
import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";
import { listingsWithMapLocations } from "../lib/mapLocations";
import PinlendMap from "./PinlendMap";

const fitBoundsPadding = { top: 60, right: 60, bottom: 190, left: 60 };

export default function ListingMapExplore({ listings, t }) {
  const mappedListings = useMemo(() => listingsWithMapLocations(listings), [listings]);
  const [selectedId, setSelectedId] = useState(null);
  const carouselRef = useRef(null);
  const dragRef = useRef({ active: false, moved: false, startX: 0, startScrollLeft: 0 });
  const suppressClickRef = useRef(false);
  const selected = mappedListings.find((item) => item.id === selectedId) || mappedListings[0];

  useEffect(() => {
    if (!selected || !carouselRef.current) return;
    const card = Array.from(carouselRef.current.children).find((element) => element.dataset.mapItemId === selected.id);
    if (card) carouselRef.current.scrollTo({ left: Math.max(0, card.offsetLeft - 16), behavior: "smooth" });
  }, [selected]);

  useEffect(() => {
    const carousel = carouselRef.current;
    if (!carousel) return;
    const scrollWithWheel = (event) => {
      if (Math.abs(event.deltaX) > Math.abs(event.deltaY) || carousel.scrollWidth <= carousel.clientWidth) return;
      const maxPosition = carousel.scrollWidth - carousel.clientWidth;
      if ((event.deltaY < 0 && carousel.scrollLeft <= 0) || (event.deltaY > 0 && carousel.scrollLeft >= maxPosition)) return;
      event.preventDefault();
      event.stopPropagation();
      carousel.scrollLeft = Math.max(0, Math.min(maxPosition, carousel.scrollLeft + event.deltaY));
    };
    carousel.addEventListener("wheel", scrollWithWheel, { passive: false });
    return () => carousel.removeEventListener("wheel", scrollWithWheel);
  }, [mappedListings.length]);

  function scrollCards(direction) {
    const carousel = carouselRef.current;
    if (carousel) carousel.scrollTo({ left: carousel.scrollLeft + direction * 330, behavior: "smooth" });
  }

  function startDrag(event) {
    if (event.button !== 0) return;
    dragRef.current = { active: true, moved: false, startX: event.clientX, startScrollLeft: event.currentTarget.scrollLeft };
  }

  function moveDrag(event) {
    const drag = dragRef.current;
    if (!drag.active) return;
    const distance = event.clientX - drag.startX;
    if (Math.abs(distance) < 5 && !drag.moved) return;
    drag.moved = true;
    event.preventDefault();
    event.currentTarget.scrollLeft = drag.startScrollLeft - distance;
  }

  function endDrag() {
    const drag = dragRef.current;
    drag.active = false;
    if (drag.moved) {
      suppressClickRef.current = true;
      window.setTimeout(() => { suppressClickRef.current = false; }, 0);
    }
  }

  function handleCardClick(event) {
    if (!suppressClickRef.current) return;
    event.preventDefault();
    event.stopPropagation();
    suppressClickRef.current = false;
  }

  return <div className="relative mb-8 h-[480px] overflow-hidden rounded-2xl bg-[#E8EDF3] shadow-sm sm:h-[520px] lg:h-[560px]">
    {selected ? <>
      <PinlendMap className="absolute inset-0 h-full w-full rounded-none" fitBoundsPadding={fitBoundsPadding} onSelect={setSelectedId} points={mappedListings} selectedId={selected.id} />
      <div className="pointer-events-none absolute inset-x-4 bottom-[194px] z-20 flex justify-end gap-2">
        <button aria-label={t.previousMapCards} className="pointer-events-auto flex h-9 w-9 items-center justify-center rounded-full bg-white text-xl text-[#30578F] shadow-md hover:scale-105 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#30578F]" onClick={() => scrollCards(-1)} type="button">←</button>
        <button aria-label={t.nextMapCards} className="pointer-events-auto flex h-9 w-9 items-center justify-center rounded-full bg-white text-xl text-[#30578F] shadow-md hover:scale-105 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#30578F]" onClick={() => scrollCards(1)} type="button">→</button>
      </div>
      <div aria-label={t.mapCards} className="absolute inset-x-0 bottom-8 z-10 flex gap-3 overflow-x-auto overflow-y-hidden bg-transparent px-4 pb-4 pt-3 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden" onClickCapture={handleCardClick} onDragStart={(event) => event.preventDefault()} onMouseDown={startDrag} onMouseLeave={endDrag} onMouseMove={moveDrag} onMouseUp={endDrag} ref={carouselRef} role="region" tabIndex={0}>
        {mappedListings.map((item) => <Link
          className={`flex h-32 w-[275px] shrink-0 gap-3 rounded-xl border bg-white p-2.5 text-left shadow-[0_3px_10px_rgba(0,0,0,0.12)] transition-transform hover:-translate-y-1 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#30578F] sm:w-[310px] ${selected.id === item.id ? "border-[#30578F]" : "border-white"}`}
          data-map-item-id={item.id}
          href={`/anunt/${encodeURIComponent(item.slug)}`}
          key={item.id}
        >
          <div className="flex h-full w-20 shrink-0 items-center justify-center overflow-hidden rounded-lg bg-[#E8EDF3] sm:w-24">
            {item.image ? <img alt="" className="h-full w-full object-cover" decoding="async" loading="lazy" src={item.image} /> : <span className="px-2 text-center text-[10px] text-[#626977]">{t.noImage}</span>}
          </div>
          <div className="flex min-w-0 flex-1 flex-col py-1">
            <strong className="line-clamp-2 text-sm leading-tight text-[#1B1B1B]">{item.title}</strong>
            <span className="mt-1 truncate text-xs text-[#434750]">{item.city || t.unknownCity}</span>
            {item.approximate && <span className="truncate text-[10px] text-[#626977]">{t.approximateLocation}</span>}
            <span className="mt-auto flex items-center justify-between gap-1 text-sm font-bold text-[#30578F]"><span className="truncate">{item.price}</span><span aria-hidden="true" className="text-lg text-[#1B1B1B]">→</span></span>
          </div>
        </Link>)}
      </div>
    </> : <p className="flex h-full items-center justify-center p-5 text-[#626977]">{t.noMap}</p>}
  </div>;
}
