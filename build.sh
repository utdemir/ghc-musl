#!/usr/bin/env bash

set -o errexit
set -o nounset

function trace() {
    echo "! $@" >&2
    "$@"
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CONFIG="$DIR/config.json"

VERSION="$(jq -r '.version' "$CONFIG")"

declare -a tags

jq -c '.flavours[]' "$CONFIG" | {
while read params; do
  ghc_version="$(
    echo "$params" \
      | jq -r '.GHC_VERSION' \
      | tr -d '.' \
  )"

  args=$(
    echo "$params" \
      | jq -r '
          to_entries
            | map(["--build-arg", "\(.key)=\(.value)"])
            | flatten | join(" ")
        '
  )

  target_tag="utdemir/ghc-musl:$VERSION-ghc$ghc_version"

  tmpdir="$(mktemp -d)"
  image="$(
    docker build \
      -f "$DIR/Dockerfile" \
      $args \
      "$(mktemp -d)" \
      | tee /dev/stderr \
      | tail -n 1 \
      | grep -Po '(?<= ).{12}$'
  )"
  rmdir "$tmpdir"

  trace docker tag "$image" "$target_tag-dev"
  trace "$DIR/test/test.sh" "$target_tag-dev"
  trace docker tag "$image" "$target_tag"

  tags+=("$target_tag")
done

echo "Done. Created tags:"
for tag in "${tags[@]}"
do
     echo "$tag"
done
}
