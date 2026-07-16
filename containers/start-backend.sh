#!/bin/sh

set -eu

node /app/latex-to-svg/index.js &
node_pid=$!

rust-extras &
rust_pid=$!

stop_services() {
  trap - HUP INT TERM
  kill -TERM "$node_pid" "$rust_pid" 2>/dev/null || true
  wait "$node_pid" 2>/dev/null || true
  wait "$rust_pid" 2>/dev/null || true
}

trap 'stop_services; exit 129' HUP
trap 'stop_services; exit 130' INT
trap 'stop_services; exit 143' TERM

while kill -0 "$node_pid" 2>/dev/null && kill -0 "$rust_pid" 2>/dev/null; do
  sleep 1
done

node_was_running=false
rust_was_running=false
kill -0 "$node_pid" 2>/dev/null && node_was_running=true
kill -0 "$rust_pid" 2>/dev/null && rust_was_running=true

kill -TERM "$node_pid" "$rust_pid" 2>/dev/null || true

set +e
wait "$node_pid"
node_status=$?
wait "$rust_pid"
rust_status=$?
set -e

stop_services

if [ "$node_was_running" = false ]; then
  exit "$node_status"
fi
if [ "$rust_was_running" = false ]; then
  exit "$rust_status"
fi
exit 1
