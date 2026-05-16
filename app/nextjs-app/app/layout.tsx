export const metadata = {
  title: "test-auth",
  description: "Minimal xnode-auth + Reown SSR repro",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body style={{ fontFamily: "system-ui, sans-serif", padding: 24, maxWidth: 720 }}>
        {children}
      </body>
    </html>
  );
}
