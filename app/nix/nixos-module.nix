{
  pkgs,
  lib,
  xnodeDomain ? "test-auth.build.openmesh.cloud",
  ...
}:
let
  testApp = pkgs.callPackage ./package.nix { };
in
{
  config = {
    # ─── The minimal Next.js test app ────────────────────────────────
    # Just enough to surface the suspected xnode-auth/Reown SSR hang
    # without any other v10 noise (no postgres, no anubis, no crons,
    # no microcache, no tmpfs mounts, no admin gates).
    systemd.services.test-auth = {
      wantedBy = [ "multi-user.target" ];
      description = "test-auth minimal Next.js app";
      after = [ "network.target" ];
      environment = {
        HOSTNAME = "0.0.0.0";
        PORT = "3000";
        NODE_ENV = "production";
      };
      serviceConfig = {
        ExecStart = "${lib.getExe testApp}";
        DynamicUser = true;
        CacheDirectory = "test-auth";
      };
    };

    # ─── nginx ──────────────────────────────────────────────────────
    # Single vhost. Three locations: public root, auth-gated /protected,
    # auth-gated /api. xnode-auth's @login redirect goes to https://$host
    # (TLS terminated externally at xnode-manager reverse-proxy).
    services.nginx = {
      enable = true;
      virtualHosts."test-auth" = {
        serverName = xnodeDomain;
        listen = [
          {
            port = 8080;
            addr = "0.0.0.0";
          }
        ];
        locations."/" = {
          proxyPass = "http://127.0.0.1:3000";
          extraConfig = "proxy_set_header Host $host;";
        };
        locations."/protected" = {
          proxyPass = "http://127.0.0.1:3000";
          extraConfig = "proxy_set_header Host $host;";
        };
        locations."/api" = {
          proxyPass = "http://127.0.0.1:3000";
          extraConfig = "proxy_set_header Host $host;";
        };
        locations."@login" = {
          return = lib.mkForce ''302 https://$host/xnode-auth?redirect=https://$host$request_uri'';
        };
      };
    };

    # ─── xnode-auth ──────────────────────────────────────────────────
    # Pinned to xnode-auth `dev` branch (see flake.nix) for the per-domain
    # config.ethereum.projectid option. Principal prefix is `ethereum:`
    # on dev (was `eth:` on main).
    #
    # The Reown project id below is the *public* identifier (security is
    # in the Reown-side domain whitelist — test-auth.build.openmesh.cloud
    # is whitelisted for this id). Not a secret.
    services.xnode-auth.enable = true;
    services.xnode-auth.domains."test-auth" = {
      # dev branch uses role-based access (users → roles → paths).
      # All authenticated ethereum users get the "anyone" role, which
      # has access to all auth-gated paths.
      accessList = {
        users = {
          "regex:^ethereum:.*$" = {
            roles = [ "anyone" ];
          };
        };
        roles = {
          "anyone" = {
            paths = ".*";
          };
        };
      };
      paths = [
        "/protected"
        "/api"
      ];
      config = {
        ethereum = {
          rpc = "https://eth.llamarpc.com";
          projectid = "7e1b35c4e28938e616af208cea516588";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 8080 ];
  };
}
