#!/bin/sh

TAG=`git describe --abbrev=0 HEAD`
REV_SHORT=`git rev-parse --short HEAD`
REV_LONG=`git rev-parse HEAD`

cat <<EOF
----
-- \`alive\` source code version information.
--
-- @module version

--- exports
-- @table exports
-- @tfield string tag the last versions git tag
-- @tfield string rev_short the short git revision hash
-- @tfield string rev_long the full git revision hash
-- @tfield string repo the git repo URL
-- @tfield string web the repo web URL
{
  tag: "${TAG}"
  rev_short: "${REV_SHORT}"
  rev_long: "${REV_LONG}"
  repo: "https://github.com/s-ol/alivecoding.git"
  web: "https://github.com/s-ol/alivecoding/releases/tag/${TAG}"
}
EOF
