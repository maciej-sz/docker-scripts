#!/usr/bin/env bash

LIBS_DIR="/opt/maciej-sz/bash-scripts"; if [[ ! -r "$LIBS_DIR" ]]; then echo "Installing Bash libs..."; sudo git clone https://github.com/maciej-sz/bash-scripts.git "$LIBS_DIR/"; fi
. "$LIBS_DIR/lib/prompt-yes-no.sh"

set -e

BUILD_PROVIDED=0
BUILD=0

SSH_PORT_PROVIDED=0
SSH_PORT=0

while test ${#} -gt 0
do
    IFS="=" read -r -a parts <<< "$1"
    shift
    arg_name=${parts[0]}
    arg_val=${parts[1]}
    case ${arg_name} in
        --build)
            BUILD_PROVIDED=1
            BUILD=${arg_val}
            continue
            ;;
        --ssh-port)
            SSH_PORT_PROVIDED=1
            SSH_PORT=${arg_val}
            continue
            ;;
        *)
            echo "ERROR: Unrecognized parameter: $arg_name" 1>&2
            exit 1
    esac
done

if [[ "0" == "$BUILD_PROVIDED" ]]; then
    BUILD=$(promptyn "Build first?")
fi

if [[ "0" == "$SSH_PORT_PROVIDED" ]]; then
    read -p "SSH port: " SSH_PORT
fi

if [[ "1" == "$BUILD" ]]; then
    echo "Building..."
    docker rm -f oxio_ubuntu_php
    ./build.sh
fi

docker run -p ${SSH_PORT}:22 --name ${DOCKER_CONTAINER_NAME} -dit oxio/ubuntu-base

echo "Running: ${DOCKER_CONTAINER_NAME}"