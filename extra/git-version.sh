#!/bin/sh

TAG=`git describe --abbrev=0 HEAD`
REV_SHORT=`git rev-parse --short HEAD`
REV_LONG=`git rev-parse HEAD`

cat <<EOF
{
  tag: "${TAG}"
  rev_short: "${REV_SHORT}"
  rev_long: "${REV_LONG}"
}
EOF
