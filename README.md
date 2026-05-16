# test-auth

Minimal repro of the 42-second SSR hang seen on `community.openxai.org`.

## Hypothesis under test

The `xnode-v10` container has a fixed ~42s TTFB on every authenticated
page, regardless of which page. Other simpler containers on the same host
(`hermes-dashboard`, `hello-world`, `own-router-gateway`, …) don't show
this. Two competing diagnoses:

1. **xnode-auth running inside the container** (with its hardcoded Reown
   AppKit SSR-init `ssr: true`) hits an outbound-connectivity or
   SDK-internal timeout on every authed request.
2. **Something v10-specific** in our 875-line nixos-module (postgres /
   anubis / nginx microcache / tmpfs mounts / cron timers / …) is causing
   it; xnode-auth is innocent.

This app strips everything from category 2 and runs only the minimum
needed to reproduce category 1.

## Layout

| File | Purpose |
|---|---|
| `app/flake.nix` | Same chassis shape as v10. `xnode-auth.url` pinned to **dev** branch for the per-domain `config.ethereum.projectid` option. |
| `app/nix/nixos-module.nix` | nginx (single vhost) + `services.xnode-auth.enable = true` + the Next.js app systemd unit. **No postgres / anubis / crons / microcache / tmpfs.** |
| `app/nix/package.nix` | Builds Next.js standalone via `buildNpmPackage`. |
| `app/nextjs-app/` | Tiny Next.js app: `/` public, `/protected` and `/api/me` xnode-auth-gated. |

## Test plan

Deploy to xnode-1 only; never prod. Time these three:

```bash
# Public — should be fast (~200-1000 ms warm)
curl -w '\nTTFB=%{time_starttransfer}s\n' https://test-auth.build.openmesh.cloud/

# Auth-gated, no cookie — expect 302 to xnode-auth (fast)
curl -I https://test-auth.build.openmesh.cloud/protected

# Auth-gated, with valid auth cookies — THE critical measurement
curl -H "Cookie: <xnode_auth_*>" https://test-auth.build.openmesh.cloud/protected
```

| Outcome on third request | Diagnosis | Next action |
|---|---|---|
| ~42 s TTFB | xnode-auth/Reown is the cause | Patch xnode-auth (fork: set `ssr: false`, or skip BlockchainApi init) |
| <2 s TTFB | v10's own config is the cause | Bisect v10's nixos-module to find which line introduces the hang |

## Reown project id

The Reown project id baked into `app/nix/nixos-module.nix` is
**public-by-design** (think rate-limit key, not auth secret). Reown
enforces a server-side domain whitelist; only domains the project owner
has registered get to use the id. `test-auth.build.openmesh.cloud` is
whitelisted for this id.

## Deploy

```bash
SHA=$(git rev-parse HEAD)
om --profile xnode-1-v10 app deploy \
  --flake "github:johnforfar/test-auth/${SHA}?dir=app" \
  --timeout 600 test-auth
```

## Removal

```bash
om --profile xnode-1-v10 app remove test-auth
```

Plus remove the `test-auth.build.openmesh.cloud` reverse-proxy rule from
the xnode-1 host config.
