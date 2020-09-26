#!/usr/bin/env bash

set -o xtrace
set -o errexit

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

image=$1

tmpdir=$(mktemp -d)
cp -r "$DIR/../example" "$tmpdir/"

cd "$tmpdir"

cat "$DIR/test-cabal.sh" |
  docker run \
    --rm -v "$tmpdir"/example:/mnt \
    -i "$image" bash

cd "$tmpdir/example"

stack build \
  --ghc-options ' -static -optl-static -optl-pthread -fPIC' \
  --docker --docker-image "$image" \
  --no-nix
