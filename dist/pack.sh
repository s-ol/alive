#!/bin/sh
set -e

VERSION="$1"
REVISION="${2:-1}"

VERSION="${VERSION#v}"
VERSION=$(echo "$VERSION" | tr -d -)

luarocks build "dist/rocks/alive-$VERSION-$REVISION.rockspec" \
  --pack-binary-rock \
  --sign \
  --pin
