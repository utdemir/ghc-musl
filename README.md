# ghc-musl

This repository provides Docker images with GHC compiled with `musl`;
therefore can be used to create fully static Haskell binaries without
`glibc` dependency on any platform which can run Docker.

Images come with `ghc` and `cabal` executables alongside with commonly
used libraries and build tools.

Here is the latest images currently published in Docker Hub:

* `utdemir/ghc-musl:v2-ghc844`
* `utdemir/ghc-musl:v2-ghc865`
* `utdemir/ghc-musl:v2-ghc881`

## Usage

Add `ghc-options: -static -optl-static -optl-pthread -fPIC` flags to
your cabal file.

### cabal-install

Mount the project directory to the container, and use `cabal-install`
inside the container:

```
$ cd myproject/
$ docker run -itv $(pwd):/mnt utdemir/ghc-musl:v2-ghc865
sh$ cd /mnt
sh$ cabal new-update
sh$ cabal new-build
```

### stack

Add these lines to your `stack.yaml`, and use `stack` as usual on the
host machine:

```
docker:
  enable: true
  image: ghc-musl:v2-ghc865
```

Make sure to pick an image with the GHC version compatible with the
Stackage resolver you are using.

## Development

Images are generated using Nix. Building an image requires a Linux
machine with KVM support.

Musl-compiled GHC and libraries are not in official NixOS cache, so
prepare to build a lot. To speed it up, you can use the cache I maintain
at [utdemir.cachix.org]().

Feel free to open an issue or send a PR to add a library or support a
newer compiler version.

## TODO

* Support using `integer-simple` instead of `libgmp`.

## Related

* https://github.com/nh2/static-haskell-nix
* https://github.com/fpco/docker-static-haskell
