{
  description = "backup-scripts dev environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        k3s_etcd_inputs = with pkgs; [
          bash
          openssl
          zstd
        ];

        mongodb_backup_inputs = with pkgs; [
          bash
          openssl
          zstd
          mongodb-tools
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          # hardeningDisable = [ "all" ];

          buildInputs = k3s_etcd_inputs ++ [];

          shellHook = ''
          '';
        };

        packages.k3s-etcd = pkgs.stdenv.mkDerivation {
          name = "k3s-etcd";
          src = pkgs.buildEnv {
            name = "k3s-etcd-env";
            paths = k3s_etcd_inputs;
          };
          # installPhase = "mkdir -p $out;cp -r $src/bin $out/bin; cp -r $src/lib $out/lib";
          installPhase = "cp -r $src $out";
        };

        packages.mongodb-backup = pkgs.stdenv.mkDerivation {
          name = "mongodb-backup";
          src = pkgs.buildEnv {
            name = "mongodb-backup";
            paths = mongodb_backup_inputs;
          };
          # installPhase = "mkdir -p $out;cp -r $src/bin $out/bin; cp -r $src/lib $out/lib";
          installPhase = "cp -r $src $out";
        };
      }
    );
}
