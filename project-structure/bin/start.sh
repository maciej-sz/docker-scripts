#!/usr/bin/env bash

. "$(dirname $0)/../config/script_params.sh"
. "$(dirname $0)/../config/build_params.sh"

LIBS_DIR="/opt/maciej-sz/docker-scripts"; if [[ ! -r "$LIBS_DIR" ]]; then echo "Installing Bash libs..."; sudo git clone https://github.com/maciej-sz/docker-scripts.git "$LIBS_DIR/"; fi
. "$LIBS_DIR/sh/start-common.sh"