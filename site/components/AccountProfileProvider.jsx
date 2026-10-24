import { createContext, useCallback, useContext, useEffect, useRef, useState } from "react";
import { useRouter } from "next/router";

const AccountProfileContext = createContext(null);

export function AccountProfileProvider({ children }) {
  const { pathname } = useRouter();
  const [profile, updateProfile] = useState(null);
  const lastChecked = useRef(0);
  const profileVersion = useRef(0);
  const setProfile = useCallback((user) => {
    profileVersion.current += 1;
    updateProfile(user);
  }, []);

  useEffect(() => {
    if (pathname === "/account" || Date.now() - lastChecked.current < 10 * 60 * 1000) return;
    lastChecked.current = Date.now();
    const version = profileVersion.current;
    fetch("/api/account/me", { credentials: "same-origin", cache: "no-store" })
      .then((response) => response.ok ? response.json() : null)
      .then((user) => {
        if (profileVersion.current === version) {
          profileVersion.current += 1;
          updateProfile(user);
        }
      })
      .catch(() => {});
  }, [pathname]);

  return <AccountProfileContext.Provider value={{ profile, setProfile }}>
    {children}
  </AccountProfileContext.Provider>;
}

export function useAccountProfile() {
  const context = useContext(AccountProfileContext);
  if (!context) throw new Error("useAccountProfile must be used inside AccountProfileProvider");
  return context;
}
