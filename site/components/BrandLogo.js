import Image from "next/image";
import Link from "next/link";

export default function BrandLogo() {
  return (
    <Link href="/" className="inline-flex shrink-0 items-center" aria-label="PINLEND - Acasa">
      <Image src="/logo.svg" alt="PINLEND" width={196} height={42} className="h-9 w-auto" priority />
    </Link>
  );
}
