#!/usr/bin/env bash

set -o xtrace
set -o errexit

cabal new-update

cd /mnt
cabal new-build example
