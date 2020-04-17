#!/bin/sh
set -e

TAG="$1"
REVISION="${2:-1}"

VERSION="${TAG#v}"
VERSION=$(echo "$VERSION" | tr -d -)
ROCKVER="$VERSION-$REVISION"

luarocks build "dist/rocks/alive-$ROCKVER.rockspec" \
  --pack-binary-rock \
  --sign \
  --pin
mv "alive-$ROCKVER.all.rock" "alive-$ROCKVER.all.rock.asc" dist/rocks

dist/pack-win.sh "$TAG" "$ROCKVER"
