import Link from "next/link";
import { useAccountProfile } from "./AccountProfileProvider";
import UserAvatar from "./UserAvatar";

export default function AccountAvatarLink({ label, className = "" }) {
  const { profile } = useAccountProfile();
  return <Link aria-label={label} className={`group flex items-center gap-2.5 font-mono text-xs uppercase tracking-widest text-black ${className}`} href="/account">
    <UserAvatar user={profile} />
    <span className="hidden group-hover:underline group-focus-visible:underline sm:inline">{label}</span>
  </Link>;
}
