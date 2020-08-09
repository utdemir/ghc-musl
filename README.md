# ghc-musl

This repository provides Docker images with GHC compiled with `musl`;
therefore can be used to create fully static Haskell binaries without
`glibc` dependency on any platform which can run Docker (x86_64).

Images come with `ghc` and `cabal` executables alongside with commonly
used libraries and build tools. They can also be used with the `stack`
build tool using its Docker integration.

Here are the latest images currently published in Docker Hub:

* `utdemir/ghc-musl:v12-libgmp-ghc8101`
* `utdemir/ghc-musl:v12-integer-simple-ghc8101`
* `utdemir/ghc-musl:v12-libgmp-ghc883`
* `utdemir/ghc-musl:v12-integer-simple-ghc883`
* `utdemir/ghc-musl:v12-libgmp-ghc865`
* `utdemir/ghc-musl:v12-integer-simple-ghc865`

## Usage

### cabal-install

Mount the project directory to the container, and use `cabal-install`
with `--enable-executable-static` flag inside the container:

```
$ cd myproject/
$ docker run -itv $(pwd):/mnt utdemir/ghc-musl:v12-libgmp-ghc8101
sh$ cd /mnt
sh$ cabal new-update
sh$ cabal new-build --enable-executable-static
```

You can also set `executable-static` [option](https://cabal.readthedocs.io/en/latest/cabal-project.html#cfg-field-executable-static) on your `cabal.project `file.

### stack

Add `ghc-options: -static -optl-static -optl-pthread -fPIC` flags to the `executable` section
of your `cabal` file and these lines to your `stack.yaml`, and use `stack` as usual on the
host machine:

```
docker:
  enable: true
  image: utdemir/ghc-musl:v12-libgmp-ghc8101
```

Make sure to pick an image with the GHC version compatible with the
Stackage resolver you are using.

Follow https://github.com/commercialhaskell/stack/issues/3420 for
more details on static compilation using the Stack build tool.

## Development

Images are generated using Nix. Building an image requires a Linux
machine with KVM support.

Musl-compiled GHC and libraries are not in official NixOS cache, so
prepare to build a lot. To speed it up, you can use the cache I maintain
at [utdemir.cachix.org]().

Feel free to open an issue or send a PR to add a library or support a
newer compiler version.

## Related

* Without using Nix: <https://gitlab.com/neosimsim/docker-builder-images>
* Without using Docker: <https://github.com/nh2/static-haskell-nix>
* Not maintained: <https://github.com/fpco/docker-static-haskell>
