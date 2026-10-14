import { NextRequest, NextResponse } from "next/server";
import { backend, COOKIE } from "@/lib/backend";
import { isSameOrigin } from "@/lib/same-origin";

type Context = { params: Promise<{ path: string[] }> };
const readable = new Set(["me", "overview", "users", "deletions", "products", "orders", "viewings", "sellers"]);

async function handle(request: NextRequest, context: Context) {
  const { path } = await context.params;
  const token = request.cookies.get(COOKIE)?.value;
  if (!token) return NextResponse.json({ message: "Autentificare necesară." }, { status: 401 });
  const moderation = request.method === "PATCH" && path.length === 3 && path[0] === "products" && /^[a-f\d]{24}$/i.test(path[1]) && path[2] === "moderation";
  if (!(request.method === "GET" && path.length === 1 && readable.has(path[0])) && !moderation)
    return NextResponse.json({ message: "Rută indisponibilă." }, { status: 404 });
  // Browser origin must match for mutations even with same-site cookies.
  if (moderation && !isSameOrigin(request))
    return NextResponse.json({ message: "Origine invalidă." }, { status: 403 });
  const suffix = request.method === "GET" ? request.nextUrl.search : "";
  try {
    const result = await backend(`/admin/${path.join("/")}${suffix}`, token, {
      method: request.method,
      ...(moderation ? { body: await request.text() } : {}),
    });
    return new NextResponse(await result.text(), {
      status: result.status,
      headers: { "Content-Type": result.headers.get("content-type") || "application/json", "Cache-Control": "no-store" },
    });
  } catch { return NextResponse.json({ message: "Backendul nu este disponibil." }, { status: 502 }); }
}

export const GET = handle;
export const PATCH = handle;
