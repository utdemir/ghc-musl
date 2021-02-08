#!/usr/bin/env bash

set -o errexit
set -o nounset

function trace() {
    echo "! $@" >&2
    "$@"
}

cd "$( dirname "${BASH_SOURCE[0]}" )"
VERSION="$(jq -r '.version' config.json)"

jq -c '.flavours[]' config.json | {
declare -a tags

while read params; do
  echo "$params"
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
      -f "Dockerfile" \
      $args \
      "$(mktemp -d)" \
      | tee /dev/stderr \
      | tail -n 1 \
      | grep -Po '(?<= ).{12}$'
  )"
  rmdir "$tmpdir"

  trace docker tag "$image" "$target_tag-dev"
  echo | trace "./test/test.sh" "$target_tag-dev"
  trace docker tag "$image" "$target_tag"

  tags+=("$target_tag")
done

echo "Done, written TAGS."
echo -n >TAGS
for tag in "${tags[@]}"
do
     echo "$tag" >> TAGS
done
}
