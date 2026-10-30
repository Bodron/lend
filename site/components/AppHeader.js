import { useRouter } from "next/router";
import PublicHeader from "./PublicHeader";

export default function AppHeader() {
  const { pathname } = useRouter();
  return <>
    <PublicHeader current={pathname} />
    <div aria-hidden="true" className="h-20" />
  </>;
}
