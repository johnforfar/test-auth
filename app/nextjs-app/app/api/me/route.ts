import { headers } from "next/headers";

export const dynamic = "force-dynamic";

export async function GET() {
  const t0 = Date.now();
  const h = await headers();
  return Response.json({
    user: h.get("Xnode-Auth-User"),
    serverTimingMs: Date.now() - t0,
    renderedAt: new Date().toISOString(),
  });
}
