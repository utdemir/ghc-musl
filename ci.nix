let

compilers = [ "ghc844" "ghc865" "ghc881" ];
build = c: import ./default.nix { compiler=c; };

sources = import ./nix/sources.nix;
pkgs = import sources.nixpkgs {};
lib = pkgs.lib;

in
rec {
  images =
    pkgs.recurseIntoAttrs (
      lib.genAttrs compilers (c: (build c).build));

  uploadAll = pkgs.writeScript "uploadAll" ''
    #!/usr/bin/env bash
    set -xe
    ${lib.concatMapStringsSep
        "\n"
        (c: "${(build c).upload}")
        compilers}
  '';
}
