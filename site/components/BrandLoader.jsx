export default function BrandLoader({ label = "Se încarcă...", overlay = false, className = "" }) {
  return <div className={`${overlay ? "fixed inset-0 z-[110] flex items-center justify-center bg-[#f9f9f9]/90 backdrop-blur-sm" : "flex flex-col items-center justify-center"} ${className}`} role="status">
    <div className="flex flex-col items-center gap-2">
      <svg aria-hidden="true" className="pinlend-loader h-[75px] w-[150px] text-[#30578F]" viewBox="0 0 300 150" xmlns="http://www.w3.org/2000/svg">
        <path d="M275 75c0 31-27 50-50 50-58 0-92-100-150-100-28 0-50 22-50 50s23 50 50 50c58 0 92-100 150-100 24 0 50 19 50 50Z" fill="none" stroke="currentColor" strokeDasharray="300 385" strokeDashoffset="685" strokeLinecap="round" strokeWidth="15" />
      </svg>
      <span className="font-mono text-[11px] uppercase tracking-[0.18em] text-[#30578F]">{label}</span>
    </div>
  </div>;
}
