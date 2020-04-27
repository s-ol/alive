#!/bin/sh
set -e

TAG="${1:-scm}"
REVISION="${2:-1}"

if [ "$TAG" = scm ]; then
  WHERE=""
  TAG=""
  VERSION="scm"
else
  VERSION="${TAG#v}"
  VERSION=$(echo "$VERSION" | tr -d -)

  if [ ! -z "$(git status --porcelain -uno)" ]; then
    echo "working directory not clean!"
    exit 2
  fi

  cat <<EOF >"alv/version.moon"
----
-- \`alive\` source code version information.
--
-- @module version

--- exports
-- @table exports
-- @tfield string tag the last versions git tag
-- @tfield string web the repo web URL
-- @tfield string repo the git repo URL
-- @tfield string release the web URL of this release
{
  tag: "${TAG}"
  web: "https://github.com/s-ol/alive"
  repo: "https://github.com/s-ol/alive.git"
  release: "https://github.com/s-ol/alive/releases/tag/${TAG}"
}
EOF

  WHERE="
  tag = \"$TAG\","
fi

list_modules() {
  for FILE in $(git ls-files "$1" | grep '\.moon$'); do
    MODULE=$(echo "$FILE" | sed -e "s/\.moon$//" -e "s/\//./g")
    echo "      [\"$MODULE\"] = \"$FILE\","
  done
}

cat <<STOP >"dist/rocks/alive-$VERSION-$REVISION.rockspec"
package = "alive"
version = "$VERSION-$REVISION"

source = {
  url = "git://github.com/s-ol/alive.git",$WHERE
}

description = {
  summary = "Experimental livecoding environment with persistent expressions",
  detailed = [[
This is an experimental livecoding language and environment, in which
expressions persist and update until they are removed from the source code, and
the interpreter keeps no state that you cannot manipulate directly in the
source. This yields a direct-manipulation like experience with a purely
text-based language and works without special editor support.]],
  homepage = "https://alive.s-ol.nu",
  license = "GPL-3",
}

dependencies = {
  "lua",
  "moonscript >= 0.5.0",
  "lpeg ~> 0.10",
  "luafilesystem",
  "luasystem",
  "luasocket",
  "osc",
}

build = {
  type = "builtin",
  modules = {},
  copy_directories = { "docs" },
  install = {
    lua = {
$(list_modules alv)

$(list_modules alv-lib)
    },
    bin = {
      "bin/alv",
      "bin/alv-wx"
    },
  },
}
STOP

if [ -n "$TAG" ]; then
  git add "alv/version.moon" "dist/rocks/alive-$VERSION-$REVISION.rockspec"
  git commit -m "release $TAG"
  git tag -am "version $TAG" "$TAG"

  luarocks pack "dist/rocks/alive-$VERSION-$REVISION.rockspec" \
    --sign
  mv "alive-$VERSION-$REVISION.src.rock" "alive-$VERSION-$REVISION.src.rock.asc" dist/rocks
  luarocks make "dist/rocks/alive-$VERSION-$REVISION.rockspec" \
    --pack-binary-rock \
    --sign
  mv "alive-$VERSION-$REVISION.all.rock" "alive-$VERSION-$REVISION.all.rock.asc" dist/rocks
  dist/pack-win.sh "$TAG" "$VERSION-$REVISION"
fi
