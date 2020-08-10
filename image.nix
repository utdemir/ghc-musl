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

name = "utdemir/ghc-musl";
tag = lib.concatStringsSep "-" [
  "v12"
  (if integer-simple then "integer-simple" else "libgmp")
  compiler
];

fullName = "${name}:${tag}";

pkgsMusl = pkgsOrig.pkgsMusl;

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
    curl.out (curl.override { stdenv = makeStaticLibraries stdenv; }).out
    pcre.dev pcre.out (pcre.override { stdenv = makeStaticLibraries stdenv; }).out
    pcre2.dev pcre2.out (pcre2.override { stdenv = makeStaticLibraries stdenv; }).out
    openssl.dev openssl.out (openssl.override { static = true; }).out
    bzip2.dev bzip2.out (bzip2.override { linkStatic = true; }).out
    curl.out (curl.override { stdenv = makeStaticLibraries stdenv; }).out
    libffi (libffi.override { stdenv = makeStaticLibraries stdenv; })
    (ncursesTerminfoOverride ncurses)
    (ncursesTerminfoOverride (ncurses.override { enableStatic = true; }))
  ] ++ lib.optionals (!integer-simple) [ gmp (gmp.override { withStatic = true; }) ];

packages = (with pkgsMusl; [
  coreutils gitMinimal
  binutils binutils-unwrapped curl
  gcc pkgconfig automake autoconf
]) ++ (with pkgsOrig; [
  bash gnused gnugrep gawk
  shadow cacert
  findutils perl gzip file
  gnutar dpkg fakeroot
]) ++ [
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
    Cmd = [ "/bin/bash" ];
    Env = [
      "PATH=${lib.makeSearchPath "bin" packages}:/bin"
      "NIX_CC_WRAPPER_TARGET_TARGET_x86_64_unknown_linux_musl=1"
      "NIX_BINTOOLS_WRAPPER_TARGET_TARGET_x86_64_unknown_linux_musl=1"
      "LD_LIBRARY_PATH=${lib.makeLibraryPath libraries}"
      "C_INCLUDE_PATH=${lib.makeSearchPathOutput "dev" "include" libraries}"
      "NIX_LDFLAGS_x86_64_unknown_linux_musl=${lib.concatMapStringsSep " " (s: "-L${lib.getOutput "lib" s}/lib") libraries}"
      "SSL_CERT_FILE=${pkgsMusl.cacert}/etc/ssl/certs/ca-bundle.crt"
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
    #   docker://${fullName}

    docker load -i ${image}
    docker push "${fullName}"
  '';

  test = pkgsOrig.writeScript "test-${name}-${tag}" ''
    #!/usr/bin/env bash
    set -x
    docker load -i ${image}
    ./test/test.sh ${fullName}
  '';
}

