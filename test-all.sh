#!/usr/bin/env sh

set -o xtrace
set -o errexit

nix-build -A contents
images="$(nix-build -A images --builders "" -j 1)"

for i in $images; do
  echo "$i"
done
