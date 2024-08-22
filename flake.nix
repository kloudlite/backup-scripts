{
  description = "backup-scripts dev environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        pkgsCross = import nixpkgs { inherit system; crossSystem = pkgs.stdenv.hostPlatform; };

        zstd = pkgs.stdenv.mkDerivation {
          name = "zstd";
          src = pkgs.zstd;
          installPhase = "mkdir -p $out/bin; cp $src/bin/zstd $out/bin";
        };

        k3s_etcd_inputs = with pkgs; [
          bash
          openssl
        ] ++ [ zstd ];

        mongodb_backup_inputs = with pkgs; [
          bash
          openssl
          # zstd
          (pkgs.stdenv.mkDerivation {
            name = "mongodump";
            src = pkgs.mongodb-tools;
            installPhase = "mkdir -p $out/bin; cp $src/bin/mongodump $out/bin";
          })
          # (mongodb-tools)
        ] ++ [ zstd ];

        nats_backup_inputs = with pkgs; [
          bash
          openssl
          natscli
        ] ++ [ zstd ];
      in
      {
        devShells.default = pkgs.mkShell {
          # hardeningDisable = [ "all" ];

          buildInputs = k3s_etcd_inputs ++ (with pkgs; [
            pre-commit
            (python312.withPackages (ps: with ps; [
              ggshield
            ]))
            s3fs
          ]);

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
          # installPhase = "cp -r $src $out";
          installPhase = ''
            mkdir -p $out
            cp -r $src/bin $out
            if [ -d "$src/lib" ]; then
              cp -r $src/lib $out
            fi
          '';
        };

        packages.mongodb-backup = pkgs.stdenv.mkDerivation {
          name = "mongodb-backup";
          src = pkgs.buildEnv {
            name = "mongodb-backup";
            paths = mongodb_backup_inputs;
          };
          installPhase = ''
            mkdir -p $out
            cp -r $src/bin $out
            # if [ -d "$out/share" ]; then
            #   rm -rf $out/share # as it's mostly man pages
            # fi
          '';
          # installPhase = "cp -r $src $out";
        };

        packages.nats-backup = pkgs.stdenv.mkDerivation {
          name = "nats-backup";
          src = pkgs.buildEnv {
            name = "nats-backup";
            paths = nats_backup_inputs;
          };
          installPhase = "cp -r $src $out";
        };
      }
    );
}
