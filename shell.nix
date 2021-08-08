let

nixpkgs =
  let rev = "f6ccdfcd2ac4f2e259d20e378737dcbd0ca7debe";
      sha256 = "1d2lk7a0l166pvgy0xfdlhxgja986hgn39szn9d1fqamyhxzvbaz";
  in builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
    inherit sha256;
  };

pkgs = import nixpkgs { config.allowUnfree = true; };

in

pkgs.mkShell {
  name = "ghc-musl-shell";
  buildInputs = [ pkgs.earthly ];
}
