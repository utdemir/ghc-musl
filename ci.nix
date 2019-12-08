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

drvs = builtins.map (import ./default.nix) flavours;

in
rec {
  images = builtins.map (c: c.image) drvs;

  uploadAll = pkgs.writeScript "uploadAll" ''
    #!/usr/bin/env bash
    set -xe
    ${lib.concatMapStringsSep
        "\n"
        (c: "${c.upload}")
        drvs}
  '';

  readme =
    pkgs.writeText
      "README.md"
      (import ./readme.nix { inherit lib; tags = builtins.map (c: c.tag) drvs; });
}
