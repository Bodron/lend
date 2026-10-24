import { createContext, useCallback, useContext, useEffect, useRef, useState } from "react";
import { useRouter } from "next/router";
import { AlertTriangle, CircleHelp } from "lucide-react";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogMedia,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

const ConfirmActionContext = createContext(null);

export function ConfirmActionProvider({ children }) {
  const router = useRouter();
  const [request, setRequest] = useState(null);
  const pending = useRef(null);

  const finish = useCallback((accepted) => {
    pending.current?.(accepted);
    pending.current = null;
    setRequest(null);
  }, []);

  const confirmAction = useCallback((options) => new Promise((resolve) => {
    if (pending.current) pending.current(false);
    pending.current = resolve;
    setRequest(options);
  }), []);

  useEffect(() => {
    const closeOnNavigation = () => finish(false);
    router.events.on("routeChangeStart", closeOnNavigation);
    return () => {
      router.events.off("routeChangeStart", closeOnNavigation);
      if (pending.current) pending.current(false);
    };
  }, [finish, router.events]);

  const destructive = request?.destructive;

  return <ConfirmActionContext.Provider value={confirmAction}>
    {children}
    <AlertDialog open={Boolean(request)} onOpenChange={(open) => { if (!open) finish(false); }}>
      <AlertDialogContent className="mx-4 w-[calc(100%-2rem)] max-w-md rounded-2xl border border-[#E6EAF0] bg-white p-6 shadow-2xl sm:max-w-md">
        <AlertDialogHeader className="text-left sm:place-items-start">
          <AlertDialogMedia className={destructive ? "rounded-xl bg-red-50 text-red-600" : "rounded-xl bg-[#E7F0FD] text-[#30578F]"}>
            {destructive ? <AlertTriangle aria-hidden="true" /> : <CircleHelp aria-hidden="true" />}
          </AlertDialogMedia>
          <AlertDialogTitle className="font-display text-xl font-bold text-[#1C1C1C]">{request?.title}</AlertDialogTitle>
          <AlertDialogDescription className="text-sm leading-6 text-[#626977]">{request?.description}</AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter className="-mx-6 -mb-6 mt-2 rounded-b-2xl bg-[#F8F9FB] px-6 py-4">
          <AlertDialogCancel onClick={() => finish(false)} className="h-10 rounded-full px-5">Renunță</AlertDialogCancel>
          <AlertDialogAction onClick={() => finish(true)} className={`h-10 rounded-full px-5 text-white ${destructive ? "bg-red-600 hover:bg-red-700" : "bg-[#30578F] hover:bg-[#244675]"}`}>
            {request?.confirmLabel || "Confirmă"}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  </ConfirmActionContext.Provider>;
}

export function useConfirmAction() {
  const confirmAction = useContext(ConfirmActionContext);
  if (!confirmAction) throw new Error("useConfirmAction must be used inside ConfirmActionProvider");
  return confirmAction;
}
