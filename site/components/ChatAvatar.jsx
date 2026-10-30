/* eslint-disable @next/next/no-img-element */
import { useEffect, useState } from "react";

function initials(name) {
  return name?.trim().split(/\s+/).slice(0, 2).map((part) => part[0]).join("").toUpperCase() || "?";
}

export default function ChatAvatar({ name, src, className = "size-8" }) {
  const [visibleSrc, setVisibleSrc] = useState(src || null);
  const [failedSrc, setFailedSrc] = useState(null);

  useEffect(() => {
    if (src === visibleSrc) return;
    if (!src) return;

    let active = true;
    const nextImage = new Image();
    nextImage.onload = () => {
      if (active) {
        setFailedSrc(null);
        setVisibleSrc(src);
      }
    };
    nextImage.onerror = () => {
      if (active && !visibleSrc) setFailedSrc(src);
    };
    nextImage.src = src;
    return () => { active = false; };
  }, [src, visibleSrc]);

  const displayed = src ? visibleSrc : null;

  return <span className={`relative flex shrink-0 overflow-hidden rounded-full bg-[#E7F0FD] ${className}`}>
    <span className="flex size-full items-center justify-center text-sm font-bold text-[#30578F]">{initials(name)}</span>
    {displayed && failedSrc !== displayed && <img
      alt={name || "Fotografia profilului"}
      className="absolute inset-0 size-full rounded-full object-cover"
      onError={() => setFailedSrc(displayed)}
      src={displayed}
    />}
  </span>;
}
