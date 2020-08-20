let
sources = import ./nix/sources.nix;
pkgs = import sources.nixpkgs {};
in
pkgs.mkShell {
  name = "ghc-musl-shell";
  buildInputs = [ pkgs.buildah ];
}
