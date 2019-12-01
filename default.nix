let
sources = import ./nix/sources.nix;
in

{ pkgsOrig ? import sources.nixpkgs { config.allowBroken = true; }
, compiler ? "ghc865"
}:

let

fixLocale = pkg: pkgsMusl.lib.overrideDerivation pkg (_: {
  LANG="C.UTF-8";
});

pkgsMusl = pkgsOrig.pkgsMusl;
haskell = pkgsMusl.haskell;
lib = pkgsMusl.stdenv.lib;

haskellPackages = haskell.packages.${compiler}.override {
  overrides = se: su: {
    # Tests don't compile with musl:
    #   hGetContents: invalid argument (invalid byte sequence)
    #   commitBuffer: invalid argument (invalid character)
    "blaze-builder" = fixLocale su.blaze-builder;
    "code-page" = fixLocale su.code-page;
    "conduit" = fixLocale su.conduit;
    "foundation" = fixLocale su.foundation;
    "hedgehog" = fixLocale su.hedgehog;
    "memory" = fixLocale su.memory;
    "retry" = fixLocale su.retry;
    "shelly" = fixLocale su.shelly;
    "tasty-hedgehog" = fixLocale su.tasty-hedgehog;
    "yaml" = fixLocale su.yaml;

    # Haddock does not work with musl:
    #   haddock: internal error: <stdout>: \
    #     commitBuffer: invalid argument (invalid character)
    #     hGetContents: invalid argument (invalid byte sequence)
    "basement" = fixLocale su.basement;
    "path-io" = fixLocale su.path-io;
  };
};

libraries = with pkgsMusl; [
  musl
  zlib zlib.static
  libffi (libffi.override { stdenv = makeStaticLibraries stdenv; })
  gmp (gmp.override { withStatic = true; })
];

packages = with pkgsMusl; [
  bash coreutils gnused gnugrep gawk
  binutils binutils-unwrapped
  gcc pkgconfig automake autoconf
] ++ [
  haskellPackages.ghc
  (haskell.lib.justStaticExecutables haskellPackages.stack)
  (haskell.lib.justStaticExecutables haskellPackages.cabal-install)
];

layered = pkgsOrig.dockerTools.buildLayeredImage {
  name = "static-ghc-granular";
  tag = "latest";
  contents = packages ++ libraries;
};

result = pkgsOrig.dockerTools.buildImage {
  name = "static-ghc";
  tag = "latest";
  fromImage = layered;
  runAsRoot = ''
    #!${pkgsMusl.stdenv.shell}
    ${pkgsMusl.dockerTools.shadowSetup}
    mkdir /tmp
  '';
  diskSize = 8192;
  config = {
    Cmd = [ "${pkgsMusl.bash}/bin/sh" ];
    Env = [
      "PATH=${lib.makeSearchPath "bin" packages}:/bin"
      "NIX_CC_WRAPPER_x86_64_unknown_linux_musl_TARGET_TARGET=1"
      "NIX_BINTOOLS_WRAPPER_x86_64_unknown_linux_musl_TARGET_TARGET=1"
      "LD_LIBRARY_PATH=${lib.makeLibraryPath libraries}"
      "C_INCLUDE_PATH=${lib.makeSearchPathOutput "dev" "include" libraries}"
      "NIX_TARGET_LDFLAGS=${lib.concatMapStringsSep " " (s: "-L${lib.getOutput "lib" s}/lib") libraries}"
    ];
  };
};

in

result
