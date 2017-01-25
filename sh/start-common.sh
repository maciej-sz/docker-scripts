#!/usr/bin/env bash

set -e

. "$(dirname $0)/../config/script_params.sh"
. "$(dirname $0)/../config/build_params.sh"

LIBS_DIR="/opt/maciej-sz/bash-scripts"; if [[ ! -r "$LIBS_DIR" ]]; then echo "Installing Bash libs..."; sudo git clone https://github.com/maciej-sz/bash-scripts.git "$LIBS_DIR/"; fi
. "$LIBS_DIR/lib/prompt-yes-no.sh"


if [[ "" == "$DOCKER_SSH_PORT" ]]; then
    read -p "SSH port: " DOCKER_SSH_PORT
fi

echo -n "Starting... "

RUN_ARGS="${RUN_ARGS} -p ${DOCKER_SSH_PORT}:22"
RUN_ARGS="${RUN_ARGS} --name ${DOCKER_CONTAINER_NAME}"
RUN_ARGS="${RUN_ARGS} --cap-add SYS_ADMIN"
if [[ "" != "${DOCKER_CONTAINER_HOSTNAME}" ]]; then RUN_ARGS="${RUN_ARGS} -h ${DOCKER_CONTAINER_HOSTNAME}"; fi
RUN_ARGS="${RUN_ARGS} -dit ${DOCKER_IMAGE_NAME}"

echo $RUN_ARGS

docker run ${RUN_ARGS}

echo "Started: ${DOCKER_CONTAINER_NAME}"