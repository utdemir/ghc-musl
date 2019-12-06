let
sources = import ./nix/sources.nix;
in

{ pkgsOrig ? import sources.nixpkgs { config.allowBroken = true; }
, compiler ? "ghc865"
}:

let

user = "utdemir";
name = "ghc-musl";
tag = "v1-${compiler}";

pkgsMusl = pkgsOrig.pkgsMusl;
haskell = pkgsMusl.haskell;
lib = pkgsMusl.stdenv.lib;

haskellPackages = haskell.packages.${compiler}.override {
  overrides = se: su: {
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
  shadow
] ++ [
  haskellPackages.ghc
  (haskell.lib.justStaticExecutables haskellPackages.cabal-install)
];

layered = pkgsOrig.dockerTools.buildLayeredImage {
  name = "${name}-layers";
  inherit tag;
  contents = packages ++ libraries;
};

image = pkgsOrig.dockerTools.buildImage {
  inherit name tag;
  fromImage = layered;
  runAsRoot = ''
    #!${pkgsMusl.stdenv.shell}
    ${pkgsMusl.dockerTools.shadowSetup}
    mkdir /tmp
    chmod a=rwx,o+t /tmp
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

{
  image=image;
  upload = pkgsOrig.writeScript "upload-${name}-${tag}" ''
    set -x
    # Ideally we would use skopeo, however somehow it doesn't
    # copy over the metadata like ENV or CMD.
    # ${pkgsOrig.skopeo}/bin/skopeo copy -f v2s2 \
    #   tarball:${image} \
    #   docker://${user}/${name}:${tag}

    cat ${image} | docker load
    docker tag "${name}:${tag}" "${user}/${name}:${tag}"
    docker push "${user}/${name}:${tag}"
  '';
}

