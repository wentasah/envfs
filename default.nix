{ pkgs ? import <nixpkgs> { }, packageSrc ? ./., enableClippy ? false }:
let
  package = pkgs.rustPlatform.buildRustPackage {
    pname = "envfs";
    version = "1.0.2";
    src = packageSrc;

    cargoLock.lockFile = ./Cargo.lock;

    postInstall = ''
      ln -s envfs $out/bin/mount.envfs
      ln -s envfs $out/bin/mount.fuse.envfs
    '';
  };
in
if enableClippy then
  package.overrideAttrs
    (old: {
      nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.clippy ];
      phases = [ "unpackPhase" "patchPhase" "installPhase" ];
      installPhase = ''
        cargo clippy -- -D warnings
        touch $out
      '';
    })
else
  package
