#!/usr/bin/env bash

LIBS_DIR="/opt/maciej-sz/docker-scripts"; if [[ ! -r "$LIBS_DIR" ]]; then echo "Installing Docker scripts..."; sudo git clone https://github.com/maciej-sz/docker-scripts.git "$LIBS_DIR/"; fi
. "$LIBS_DIR/sh/build-common.sh"