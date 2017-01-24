#!/usr/bin/env bash

. "$(dirname $0)/../config/script_params.sh"

LIBS_DIR="/opt/maciej-sz/docker-scripts"; if [[ ! -r "$LIBS_DIR" ]]; then echo "Installing Docker scripts..."; sudo git clone https://github.com/maciej-sz/docker-scripts.git "$LIBS_DIR/"; fi
. "$LIBS_DIR/sh/stop-common.sh"