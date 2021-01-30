#!/bin/sh
set -e

TAG="${1:-scm}"
REVISION="${2:-1}"
ROCK_OPTS=""
WHERE=""

list_modules() {
  for FILE in $(git ls-files "$1" | grep '\.moon$'); do
    MODULE=$(echo "$FILE" | sed -e "s/\.moon$//" -e "s/\//./g")
    echo "      [\"$MODULE\"] = \"$FILE\","
  done
}

if [ "$TAG" = "scm" ]; then
  TAG=""
  VERSION="scm"
elif [ "$TAG" = "test" ]; then
  VERSION="test"
  REVISION=999

  list_modules() {
    for FILE in $(find alv alv-lib -type f | grep '\.moon$'); do
      MODULE=$(echo "$FILE" | sed -e "s/\.moon$//" -e "s/\//./g")
      echo "      [\"$MODULE\"] = \"$FILE\","
    done
  }

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
-- @tfield string repo the repo web URL
-- @tfield string git the git repo URL
-- @tfield string web the project web URL
-- @tfield string release the web URL of this release
{
  tag: "${TAG}"
  repo: "https://github.com/s-ol/alive"
  git: "https://github.com/s-ol/alive.git"
  web: "https://alv.s-ol.nu"
  release: "https://github.com/s-ol/alive/releases/tag/${TAG}"
}
EOF

  WHERE="
  tag = \"$TAG\","

  ROCK_OPTS="--sign"
fi

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
  homepage = "https://alv.s-ol.nu",
  license = "GPL-3",
}

dependencies = {
  "lua",
  "moonscript >= 0.5.0",
  "lpeg",
  "luafilesystem",
  "luasystem",
  "luasocket",
  "losc",
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
      "bin/alv-wx",
      "bin/alv-fltk",
    },
  },
}
STOP

if [ -n "$TAG" ] && [ "$TAG" != "test" ]; then
  git add "alv/version.moon" "dist/rocks/alive-$VERSION-$REVISION.rockspec"
  git commit -m "release $TAG"
  git tag -am "version $TAG" "$TAG"

  luarocks pack "dist/rocks/alive-$VERSION-$REVISION.rockspec" $ROCK_OPTS
  mv "alive-$VERSION-$REVISION.src.rock"* dist/rocks
fi

if [ -n "$TAG" ]; then
  luarocks make "dist/rocks/alive-$VERSION-$REVISION.rockspec" $ROCK_OPTS \
    --deps-mode none --pack-binary-rock
  mv "alive-$VERSION-$REVISION.all.rock"* dist/rocks
  echo "now run this in a windows dev cmd.exe:"
  echo dist\win\release.bat "$TAG" "dist/rocks/alive-$VERSION-$REVISION.all.rock"
fi
