import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "PINLEND Admin",
  robots: "noindex, nofollow",
  icons: { icon: "/logo_mark.svg" },
};
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="ro"><body>{children}</body></html>;
}
