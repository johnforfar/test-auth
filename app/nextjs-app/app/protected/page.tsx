import { headers } from "next/headers";

export const dynamic = "force-dynamic";

export default async function Protected() {
  const t0 = Date.now();
  const h = await headers();
  const user = h.get("Xnode-Auth-User") ?? "(no Xnode-Auth-User header)";
  const elapsed = Date.now() - t0;
  return (
    <div>
      <h1>test-auth · protected</h1>
      <p>
        Authed as: <code>{user}</code>
      </p>
      <p>SSR took: {elapsed} ms</p>
      <p>Rendered at: {new Date().toISOString()}</p>
    </div>
  );
}
