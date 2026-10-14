import { NextRequest, NextResponse } from "next/server";
import { backend, COOKIE, publicBackend } from "@/lib/backend";
import { isSameOrigin } from "@/lib/same-origin";

export async function POST(request: NextRequest) {
  if (!isSameOrigin(request))
    return NextResponse.json({ message: "Origine invalidă." }, { status: 403 });
  let credentials: { email?: string; password?: string };
  try { credentials = await request.json(); } catch { return NextResponse.json({ message: "Date invalide." }, { status: 400 }); }
  if (typeof credentials.email !== "string" || typeof credentials.password !== "string")
    return NextResponse.json({ message: "Email și parolă necesare." }, { status: 400 });
  try {
    const login = await publicBackend("/auth/login", { method: "POST", body: JSON.stringify(credentials) });
    const data = await login.json();
    if (!login.ok) return NextResponse.json({ message: data.message || "Autentificare eșuată." }, { status: login.status });
    const check = await backend("/admin/me", data.accessToken);
    if (!check.ok) return NextResponse.json({ message: "Acest cont nu are rolul super_admin." }, { status: 403 });
    const response = NextResponse.json({ user: await check.json() });
    response.cookies.set(COOKIE, data.accessToken, {
      httpOnly: true, secure: new URL(request.headers.get("origin")!).protocol === "https:", sameSite: "strict",
      path: "/", maxAge: 60 * 60 * 24 * 7,
    });
    return response;
  } catch { return NextResponse.json({ message: "Backendul nu este disponibil." }, { status: 502 }); }
}

export async function DELETE(request: NextRequest) {
  if (!isSameOrigin(request))
    return NextResponse.json({ message: "Origine invalidă." }, { status: 403 });
  const response = NextResponse.json({ ok: true });
  response.cookies.delete(COOKIE);
  return response;
}
