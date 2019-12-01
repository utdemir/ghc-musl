# ghc-musl

This repository provides Docker images with GHC compiled with `musl`; therefore can be used to create fully static Haskell binaries without `glibc` dependency on any platform which can run Docker.

The images contain `ghc`, `cabal` and `stack` executables alongside with commonly used libraries and build tools.

## Usage

Add `ghc-options: -static -optl-static -optl-pthread -fPIC` flags to your cabal file.

### cabal-install

Mount the project directory to the container, and use `cabal-install` inside the container:

```
$ cd myproject/
$ docker run -itv $(pwd):/mnt utdemir/ghc-musl:v1-ghc865`
sh$ cd /mnt
sh$ cabal new-update
sh$ cabal new-build
```

### stack

Add these lines to your `stack.yaml`, and use `stack` as usual on the host machine:

```
docker:
  enable: true
  image: ghc-musl:v1-ghc865
  set-user: false
```
