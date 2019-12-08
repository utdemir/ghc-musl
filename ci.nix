let

flavours = [
  { compiler="ghc881"; integer-simple=false; }
  { compiler="ghc881"; integer-simple=true;  }
  { compiler="ghc865"; integer-simple=false; }
  { compiler="ghc865"; integer-simple=true;  }
  { compiler="ghc844"; integer-simple=false; }
];

build = import ./default.nix;

sources = import ./nix/sources.nix;
pkgs = import sources.nixpkgs {};
lib = pkgs.lib;

in
rec {
  images =
    [ lib.map flavours (c: (build c).image) ];

  uploadAll = pkgs.writeScript "uploadAll" ''
    #!/usr/bin/env bash
    set -xe
    ${lib.concatMapStringsSep
        "\n"
        (c: "${(build c).upload}")
        flavours}
  '';
}
