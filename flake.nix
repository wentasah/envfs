{
  description = "Fuse filesystem that returns symlinks to executables based on the PATH of the requesting process.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";
  inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } ({ self, ... }: {
      imports = [ ./treefmt.nix ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "riscv64-linux"
      ];
      flake.nixosModules.envfs = import ./modules/envfs.nix;
      perSystem = { lib, config, pkgs, ... }: {
        packages = {
          envfs = pkgs.callPackage ./default.nix {
            packageSrc = self;
          };
          default = config.packages.envfs;
        };
        checks =
          let
            packages = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") config.packages;
            devShells = lib.mapAttrs' (n: lib.nameValuePair "devShell-${n}") config.devShells;
          in
          packages // devShells // {
            envfsCrossAarch64 = pkgs.pkgsCross.aarch64-multiplatform.callPackage ./default.nix {
              packageSrc = self;
            };
            integration-tests = import ./nixos-test.nix {
              makeTest = import (inputs.nixpkgs + "/nixos/tests/make-test-python.nix");
              inherit pkgs;
            };
            clippy = config.packages.envfs.override { enableClippy = true; };
          };
        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.cargo pkgs.rustc pkgs.cargo-watch pkgs.clippy ];
        };
      };
    });
}
