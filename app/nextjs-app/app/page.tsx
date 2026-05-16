export const dynamic = "force-dynamic";

export default async function Home() {
  const t0 = Date.now();
  // No data fetching — pure render. SSR cost = render + serialization only.
  const elapsed = Date.now() - t0;
  return (
    <div>
      <h1>test-auth · public root</h1>
      <p>Rendered at: {new Date().toISOString()}</p>
      <p>SSR took: {elapsed} ms</p>
      <p>
        <a href="/protected">→ /protected (xnode-auth gated)</a>
      </p>
      <p>
        <a href="/api/me">→ /api/me (xnode-auth gated)</a>
      </p>
    </div>
  );
}
