{ pkgs, lib }:
pkgs.buildNpmPackage {
  pname = "test-auth";
  version = "0.1.0";
  src = ../nextjs-app;

  npmDeps = pkgs.importNpmLock {
    npmRoot = ../nextjs-app;
  };
  npmConfigHook = pkgs.importNpmLock.npmConfigHook;

  postBuild = ''
    sed -i '1s|^|#!/usr/bin/env node\n|' .next/standalone/server.js
    patchShebangs .next/standalone/server.js
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{share,bin}

    cp -r .next/standalone $out/share/test-auth/
    mkdir -p $out/share/test-auth/.next
    cp -r .next/static $out/share/test-auth/.next/static

    chmod +x $out/share/test-auth/server.js

    makeWrapper $out/share/test-auth/server.js $out/bin/test-auth \
      --set-default PORT 3000 \
      --set-default HOSTNAME 0.0.0.0

    runHook postInstall
  '';

  doDist = false;

  meta = {
    mainProgram = "test-auth";
  };
}
