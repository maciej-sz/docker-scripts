#!/usr/bin/env bash

LIBS_DIR="/opt/maciej-sz/bash-scripts"; if [[ ! -r "$LIBS_DIR" ]]; then echo "Installing Bash libs..."; sudo git clone https://github.com/maciej-sz/bash-scripts.git "$LIBS_DIR/"; fi
. "$LIBS_DIR/lib/read-password.sh"
. "$LIBS_DIR/lib/slugify-variable-name.sh"

. "$(dirname ${BASH_SOURCE[0]})/../config/script_params.sh"

FILE="$(slugifyVariableName ${DOCKER_CONTAINER_NAME})_ssh_password"

echo $(readPassword) > "/tmp/${FILE}"
echo