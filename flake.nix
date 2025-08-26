{
  description = "A Nix flake for chessdriller";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        rpath = pkgs.lib.makeLibraryPath (with pkgs; [
          stdenv.cc.cc.lib
          openssl
          zlib
        ]);

        prisma-engines-patched = pkgs.runCommand "prisma-engines-patched" {
          nativeBuildInputs = [ pkgs.patchelf ];
        } ''
          mkdir -p $out
          cp -r ${pkgs.prisma-engines}/* $out
          chmod -R +w $out
          
          find $out -type f \( -perm /u+x -o -name "*.node" \) -print0 | while IFS= read -r -d '' $file; do
            echo "Patching RPATH for ''$file"
            patchelf --set-rpath "${rpath}" "''$file"
          done
        '';

      in
      {
        packages.default = pkgs.buildNpmPackage {
          pname = "chessdriller";
          version = "0.1.0";
          src = ./.;
          npmDepsHash = "sha256-xM328/hC4P8/nFzO8HnBqWzJq0g64+gEAXUoWz17T6w=";

          nativeBuildInputs = [
            pkgs.nodejs_20
            prisma-engines-patched
          ];
          
          OPENSSL_DIR = "${pkgs.openssl.dev}";

          prebuild = ''
            export PRISMA_FMT_BINARY="${prisma-engines-patched}/bin/prisma-fmt"
            export PRISMA_QUERY_ENGINE_BINARY="${prisma-engines-patched}/bin/query-engine"
            export PRISMA_MIGRATION_ENGINE_BINARY="${prisma-engines-patched}/bin/schema-engine"
            export PRISMA_INTROSPECTION_ENGINE_BINARY="${prisma-engines-patched}/bin/schema-engine"
            export PRISMA_QUERY_ENGINE_LIBRARY="${prisma-engines-patched}/lib/libquery_engine.node"

            ./node_modules/.bin/prisma generate
          '';

          doCheck = false;
          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp -r ./* $out/
            cd $out
            npm prune --production
            runHook postInstall
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.nodejs_20
            prisma-engines-patched
            pkgs.openssl
            pkgs.sqlite
          ];

          shellHook = ''
            echo "Benvenuto nell'ambiente di sviluppo di Chessdriller!"
            echo "Le variabili d'ambiente per Prisma sono impostate correttamente."

            export PRISMA_FMT_BINARY="${prisma-engines-patched}/bin/prisma-fmt"
            export PRISMA_QUERY_ENGINE_BINARY="${prisma-engines-patched}/bin/query-engine"
            export PRISMA_MIGRATION_ENGINE_BINARY="${prisma-engines-patched}/bin/schema-engine"
            export PRISMA_INTROSPECTION_ENGINE_BINARY="${prisma-engines-patched}/bin/schema-engine"
            export PRISMA_QUERY_ENGINE_LIBRARY="${prisma-engines-patched}/lib/libquery_engine.node"
          '';
        };
      }
    );
}
