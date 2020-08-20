#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

read -r -d '' template <<'EOF' || true
<!--

WARNING: This file is auto-generated from ./update-readme.sh, modify
that instead.

-->

# ghc-musl

This repository provides Docker images with GHC compiled with `musl`;
therefore can be used to create fully static Haskell binaries without
`glibc` dependency on any platform which can run Docker (x86_64). Powered
by [ghcup](https://www.haskell.org/ghcup/).

Images come with `ghc` and `cabal` executables alongside with commonly
used libraries and build tools. They can also be used with the `stack`
build tool using its Docker integration.

Here are the latest images currently published in Docker Hub:

${ALL_TAGS}

## Usage

### cabal-install

Mount the project directory to the container, and use `cabal-install`
with `--enable-executable-static` flag inside the container:

```
$ cd myproject/
$ docker run -itv $PWD:/mnt ${EXAMPLE_TAG}
sh$ cd /mnt
sh$ cabal new-update
sh$ cabal new-build --enable-executable-static
```

You can also set `executable-static` [option](https://cabal.readthedocs.io/en/latest/cabal-project.html#cfg-field-executable-static) on your `cabal.project` file.

### stack

Add `ghc-options: -static -optl-static -optl-pthread -fPIC` flags to
the `executable` section of your `cabal` file and these lines to your
`stack.yaml`, and use `stack` as usual on the host machine:

```
docker:
  enable: true
  image: ${EXAMPLE_TAG}
```

Make sure to pick an image with the GHC version compatible with the
Stackage resolver you are using.

Follow https://github.com/commercialhaskell/stack/issues/3420 for
more details on static compilation using the Stack build tool.

### Example session with GHC

Below shell session shows how to start a pre-compiled docker container
and compile a simple `Hello.hs` as a static executable:

```
$ docker run -itv $PWD:/mnt ${EXAMPLE_TAG}
bash-4.4# cd /mnt/
bash-4.4# cat Hello.hs
main = putStrLn "Hello"
bash-4.4# ghc --make -optl-static -optl-pthread Hello.hs
[1 of 1] Compiling Main             ( Hello.hs, Hello.o )
Linking Hello ...
bash-4.4# ls -al Hello
-rwxr-xr-x 1 root root 1185056 Aug 11 16:55 Hello
bash-4.4# file Hello
Hello: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, with debug_info, not stripped
bash-4.4# ldd ./Hello
ldd: ./Hello: Not a valid dynamic program
```

The result can be executed on different Linux systems:

```
$ docker run -itv $PWD:/mnt alpine
# /mnt/Hello
Hello
```

```
$ docker run -itv $PWD:/mnt centos
[root@94eb29dcdfe6 /]# /mnt/Hello
Hello
```

## Development

Feel free to open an issue or send a PR to add a library or support a
newer compiler version.

## Related

* <https://gitlab.com/neosimsim/docker-builder-images>
* Using Nix: <https://github.com/nh2/static-haskell-nix>
* Not maintained: <https://github.com/fpco/docker-static-haskell>
EOF


cd "$( dirname "${BASH_SOURCE[0]}" )"

export ALL_TAGS="$(cat TAGS | sed 's/^/* /g')"
export EXAMPLE_TAG="$(head -n 1 TAGS | tr -d '\n')"

echo "$template" \
  | envsubst '${ALL_TAGS} ${EXAMPLE_TAG}' \
  > README.md

