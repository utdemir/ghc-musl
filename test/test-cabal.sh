#!/usr/bin/env bash

set -o xtrace
set -o errexit

cd /mnt
cabal new-build example --enable-executable-static
