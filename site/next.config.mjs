/** @type {import('next').NextConfig} */
const nextConfig = {
  /* config options here */
  reactStrictMode: true,
  devIndicators: false,
  i18n: {
    locales: ["ro", "en"],
    defaultLocale: "ro",
  },
};

export default nextConfig;
