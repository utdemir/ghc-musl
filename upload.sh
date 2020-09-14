#!/usr/bin/env sh

set -o errexit
set -o nounset

cd "$( dirname "${BASH_SOURCE[0]}" )"
cat TAGS | xargs -I {} docker push {}
