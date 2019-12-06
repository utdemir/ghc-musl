#!/usr/bin/env bash

set -o errexit
set -o xtrace

cd "$( dirname "${BASH_SOURCE[0]}" )"

compilers=( ghc844 ghc865 ghc881 )

for c in "$compilers"; do
  nix-build --argstr compiler $c
done

for c in $compilers; do
  $(nix-build --argstr compiler $c -A upload)
done
