{ compiler
, integer-simple
}:

let
sources = import ./nix/sources.nix;
pkgsOrig =
  let
    basePkgs = import sources.nixpkgs {};
    patched = basePkgs.applyPatches {
      name = "nixpkgs-patched";
      src = sources.nixpkgs;
      patches = [
        ./patches/0001-Revert-ghc-8.6.3-binary-8.6.5-binary.patch
      ];
    };
  in
    import patched { config.allowBroken = true; };

user = "utdemir";
name = "ghc-musl";
tag = lib.concatStringsSep "-" [
  "v7"
  (if integer-simple then "integer-simple" else "libgmp")
  compiler
];

pkgsMusl = pkgsOrig.pkgsMusl.extend (se: su: {
  fetchgit = pkgsOrig.fetchgit;
});

haskell = pkgsMusl.haskell;
lib = pkgsMusl.stdenv.lib;

haskellPackages =
  (if integer-simple
   then haskell.packages.integer-simple
   else haskell.packages).${compiler}.override {
  overrides = se: su: {
  };
};

libraries =
  let ncursesTerminfoOverride = c: c.overrideDerivation (old: {
      configureFlags = old.configureFlags ++
        [ "--with-terminfo-dirs=${lib.makeSearchPath "terminfo" [ "/lib" "/etc" "/usr/share" ]}" ];
  });
  in with pkgsMusl; [
    musl
    zlib zlib.static
    curl.out (libcurl.override { stdenv = makeStaticLibraries stdenv; }).out
    libffi (libffi.override { stdenv = makeStaticLibraries stdenv; })
    (ncursesTerminfoOverride ncurses)
    (ncursesTerminfoOverride (ncurses.override { enableStatic = true; }))
  ] ++ lib.optionals (!integer-simple) [ gmp (gmp.override { withStatic = true; }) ];

packages = with pkgsMusl; [
  bash coreutils gnused gnugrep gawk
  binutils binutils-unwrapped
  gcc pkgconfig automake autoconf
  shadow cacert git curl
] ++ [
  haskellPackages.ghc
  (haskell.lib.justStaticExecutables haskellPackages.cabal-install)
];

contents = packages ++ libraries;

layered = pkgsOrig.dockerTools.buildLayeredImage {
  name = "${name}-layers";
  inherit tag contents;
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
  inherit tag image contents;
  upload = pkgsOrig.writeScript "upload-${name}-${tag}" ''
    #!/usr/bin/env bash
    set -x
    # Ideally we would use skopeo, however somehow it doesn't
    # copy over the metadata like ENV or CMD.
    # ${pkgsOrig.skopeo}/bin/skopeo copy -f v2s2 \
    #   tarball:${image} \
    #   docker://${user}/${name}:${tag}

    docker load -i ${image}
    docker tag "${name}:${tag}" "${user}/${name}:${tag}"
    docker push "${user}/${name}:${tag}"
  '';
}

