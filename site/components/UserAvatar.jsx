import { UserRound } from "lucide-react";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";

function initials(name) {
  return name?.trim().split(/\s+/).slice(0, 2).map((part) => part[0]).join("").toUpperCase() || "?";
}

export default function UserAvatar({ user, className = "size-8", fallbackClassName = "", imageClassName = "" }) {
  return <Avatar className={className}>
    {user?.avatarUrl && <AvatarImage alt={user.fullName || "Fotografia profilului"} className={imageClassName} src={user.avatarUrl} />}
    <AvatarFallback className={user
      ? `bg-[#E7F0FD] font-bold text-[#30578F] ${fallbackClassName}`
      : `bg-black text-white ${fallbackClassName}`}>
      {user ? initials(user.fullName || user.email) : <UserRound aria-hidden="true" className="size-4" />}
    </AvatarFallback>
  </Avatar>;
}
