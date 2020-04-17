#!/bin/sh
set -e

TAG="${1:-scm}"
REVISION="${2:-1}"

if [ "$VERSION" = scm ]; then
  WHERE=
  VERSION="scm"
else
  VERSION="${TAG#v}"
  VERSION=$(echo "$VERSION" | tr -d -)

  if [ ! -z "$(git status --porcelain)" ]; then
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
  web: "https://github.com/s-ol/alivecoding"
  repo: "https://github.com/s-ol/alivecoding.git"
  release: "https://github.com/s-ol/alivecoding/releases/tag/${TAG}"
}
EOF

  WHERE="
  tag = \"$TAG\","

  git add "alv/version.moon"
  git commit -m "relase $TAG"
  git tag -am "version $TAG" "$TAG"
fi

list_modules() {
  find "$1" -type f -name '*.moon' -exec sh -c '
      MODULE=$(echo "$1" | sed -e "s/\.moon$//" -e "s/\//./g")
      echo "      [\"$MODULE\"] = \"$1\","
    ' sh {} \;
}

cat <<STOP >"dist/rocks/alive-$VERSION-$REVISION.rockspec"
package = "alive"
version = "$VERSION-$REVISION"

source = {
  url = "git://github.com/s-ol/alivecoding.git",$WHERE
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
  "lua >= 5.3",
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
      "bin/alv-copilot"
    },
  },
}
STOP
