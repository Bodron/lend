import { useCallback, useRef } from "react";
import { toast } from "sonner";

export function useToastNotice() {
  const activeId = useRef(null);
  return useCallback((message, tone = "success") => {
    const nextId = typeof message === "string" && message.trim() ? `notice:${message}` : null;
    if (activeId.current && activeId.current !== nextId) toast.dismiss(activeId.current);
    activeId.current = nextId;
    if (!nextId) return;
    const notify = ["success", "info", "warning"].includes(tone) ? toast[tone] : toast.success;
    notify(message, { id: nextId });
  }, []);
}
