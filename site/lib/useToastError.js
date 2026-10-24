import { useCallback, useRef, useState } from "react";
import { toast } from "sonner";

export function useToastError(initialValue = "") {
  const [error, setErrorState] = useState(initialValue);
  const activeId = useRef(null);

  const setError = useCallback((value) => {
    setErrorState(value);
    const nextId = typeof value === "string" && value.trim() ? `error:${value}` : null;
    if (activeId.current && activeId.current !== nextId) toast.dismiss(activeId.current);
    activeId.current = nextId;
    if (nextId) toast.error(value, { id: nextId });
  }, []);

  return [error, setError];
}
