#!/usr/bin/env bash

set -e

LIBS_DIR="/opt/maciej-sz/bash-scripts"; if [[ ! -r "$LIBS_DIR" ]]; then echo "Installing Bash libs..."; sudo git clone https://github.com/maciej-sz/bash-scripts.git "$LIBS_DIR/"; fi
. "$LIBS_DIR/lib/cast-bool.sh"

DOCKER_BUILD_ARGS=""
SSH_USER_PROVIDED=0
SSH_USER=""
SSH_PROMPT_PASSWORD=0
SETUP_KNOWN_HOST=0

TMP_AUTHORIZED_KEYS_DIR="$(dirname $0)/../tmp"
TMP_AUTHORIZED_KEYS_FILE="${TMP_AUTHORIZED_KEYS_DIR}/authorized_keys"
mkdir -p "$TMP_AUTHORIZED_KEYS_DIR"
touch "${TMP_AUTHORIZED_KEYS_FILE}"
echo > "${TMP_AUTHORIZED_KEYS_FILE}"

while test ${#} -gt 0
do
    param=$1
    IFS="=" read -r -a parts <<< "$1"
    shift
    arg_name=${parts[0]}
    arg_val=${parts[1]}
    case ${arg_name} in
        --ssh-user)
            SSH_USER_PROVIDED=1
            SSH_USER=${arg_val}
            continue;;
        --prompt-ssh-password)
            SSH_PROMPT_PASSWORD=$(castBool ${arg_val})
            continue;;
        --hostname)
            CONTAINER_HOSTNAME=${arg_val}
            continue;;
        --ssh-authorize-host)
            if [[ "1" == $(castBool ${arg_val}) ]]; then
                cat ~/.ssh/id_rsa.pub >> "${TMP_AUTHORIZED_KEYS_FILE}"
            fi
            continue;;
        *)
            DOCKER_BUILD_ARGS="${DOCKER_BUILD_ARGS} ${param}"
            continue;;
    esac
done

if [[ "0" == "$SSH_USER_PROVIDED" ]]; then
    read -p "SSH username: " SSH_USER
fi

SSH_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
if [[ "1" == "$SSH_PROMPT_PASSWORD" ]]; then
    read -s -p "SSH password: " SSH_PASSWORD
    echo
fi

echo $DOCKER_BUILD_ARGS

docker build \
    -t ${DOCKER_IMAGE_TAG}:latest \
    --build-arg SSH_USER=${SSH_USER} \
    --build-arg SSH_PASSWORD=${SSH_PASSWORD} \
    --build-arg CONTAINER_HOSTNAME=${CONTAINER_HOSTNAME} \
    -f Dockerfile \
    ${DOCKER_BUILD_ARGS} \
    .

echo "Built: ${DOCKER_IMAGE_TAG}"
echo "SSH username: $SSH_USER"
SSH_DISPLAY_PASSWORD=${SSH_PASSWORD}
if [[ "0" != "$SSH_PROMPT_PASSWORD" ]]; then
    LEN=${#SSH_PASSWORD}
    SSH_DISPLAY_PASSWORD=" (provided)"
    for ((i=0; i<$LEN; i++)); do SSH_DISPLAY_PASSWORD="*${SSH_DISPLAY_PASSWORD}"; done
fi
echo "SSH password: $SSH_DISPLAY_PASSWORD"