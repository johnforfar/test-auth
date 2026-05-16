{
  description = "test-auth — minimal repro of v10's xnode-auth + Reown SSR stack";

  # Mirrors xnode-v10's app/flake.nix shape so the test is apples-to-apples,
  # EXCEPT pinned to xnode-auth's `dev` branch for the per-domain
  # config.ethereum.projectid option (lets us pass a fresh Reown project id
  # that's whitelisted for test-auth.build.openmesh.cloud).
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    xnode-auth.url = "github:Openmesh-Network/xnode-auth/dev";
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      xnode-auth,
    }:
    let
      eachSystem =
        f:
        nixpkgs.lib.genAttrs (import systems) (
          system:
          f {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
          }
        );
    in
    {
      packages = eachSystem (
        { pkgs, ... }:
        {
          default = pkgs.callPackage ./nix/package.nix { };
        }
      );

      nixosModules.default =
        { ... }:
        {
          imports = [
            ./nix/nixos-module.nix
            xnode-auth.nixosModules.default
          ];
        };
    };
}
