import { Children, isValidElement } from "react";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";

const emptyValue = "__pinlend_empty__";

export default function FormSelect({ children, className = "", onChange, value, ...props }) {
  const options = Children.toArray(children).filter((child) => isValidElement(child) && child.type === "option");
  const hasEmptyOption = options.some((option) => String(option.props.value) === "");
  const selected = value === "" && hasEmptyOption ? emptyValue : String(value ?? "");

  return <Select
    disabled={props.disabled}
    onValueChange={(next) => onChange?.({ target: { value: next === emptyValue ? "" : next } })}
    value={selected}
  >
    <SelectTrigger aria-label={props["aria-label"]} className={className || "account-input"}>
      <SelectValue />
    </SelectTrigger>
    <SelectContent className="z-[100] rounded-xl border border-black/10 bg-white shadow-xl" position="popper">
      {options.map((option) => <SelectItem disabled={option.props.disabled} key={String(option.props.value)} value={String(option.props.value) || emptyValue}>
        {option.props.children}
      </SelectItem>)}
    </SelectContent>
  </Select>;
}
