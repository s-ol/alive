#!/bin/sh
set -e

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT INT TERM HUP

ARGS="$@"
FIFO=$tmpdir/fifo
CONF=$tmpdir/conf
LIBDIR=$(dirname $0)
LUA_PATH="$LIBDIR/?.lua;$LIBDIR/?/init.lua;$LUA_PATH"

cat > "$CONF" << 'EOF'
split
focus
screen -t evaltime sh -c 'tty > "$FIFO"; read done < "$FIFO"'
focus
screen -t runtime sh -c 'read tty < "$FIFO";  moon "$LIBDIR/alv/copilot.moon" $ARGS 2> "$tty";  echo "[press enter to exit]"; read prompt;  echo done > "$FIFO"'
EOF

mkfifo "$FIFO"
export FIFO ARGS LIBDIR LUA_PATH
exec screen -mc "$CONF"
