#!/bin/sh

TAG=$(git describe --abbrev=0 HEAD)
# REV_SHORT=$(git rev-parse --short HEAD)
# REV_LONG=$(git rev-parse HEAD)

cat <<EOF
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
