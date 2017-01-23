#!/usr/bin/env bash

set -e

DOCKER_BUILD_ARGS=""

SSH_USER_PROVIDED=0
SSH_USER=""

SSH_PROMPT_PASSWORD=0

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
            SSH_PROMPT_PASSWORD=1
            continue;;
        --hostname)
            CONTAINER_HOSTNAME=${arg_val}
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