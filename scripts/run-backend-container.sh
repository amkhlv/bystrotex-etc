#!/bin/sh

set -eu

image=${BYSTROTEX_BACKEND_IMAGE:-localhost/bystrotex-backend:latest}
socket_dir=${HOME}/.local/run/bystrotex
bib_path=${BYSTROTEX_BIB_PATH:-${HOME}/.config/bystrotex.bib}

if [ ! -f "$bib_path" ]; then
  printf 'Bibliography file not found: %s\n' "$bib_path" >&2
  printf 'Set BYSTROTEX_BIB_PATH to select a different file.\n' >&2
  exit 1
fi

mkdir -p "$socket_dir"
rm -f "$socket_dir/bystrotex.ipc" "$socket_dir/rust-extras.ipc"

exec podman run --rm \
  --name bystrotex-backend \
  --userns=keep-id \
  --user "$(id -u):$(id -g)" \
  --mount "type=bind,src=${socket_dir},target=/run/bystrotex" \
  --mount "type=bind,src=${bib_path},target=/config/bystrotex.bib,ro=true" \
  "$image"
