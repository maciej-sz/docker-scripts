#!/usr/bin/env bash

# Required variables:
# - DOCKER_IMAGE_TAG

set -e

SSH_USER_PROVIDED=0
SSH_USER=""

SSH_PROMPT_PASSWORD=0

while test ${#} -gt 0
do
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
            echo "ERROR: Unrecognized parameter: $arg_name" 1>&2
            exit 1
    esac
done

if [[ "0" == "$SSH_USER_PROVIDED" ]]; then
    read -p "SSH username: " SSH_USER
fi

if [[ "1" == "$SSH_PROMPT_PASSWORD" ]]; then
    read -s -p "SSH password: " SSH_PASSWORD
    echo
fi

SSH_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)

docker build \
    -t ${DOCKER_IMAGE_TAG}:latest \
    --build-arg SSH_USER=${SSH_USER} \
    --build-arg SSH_PASSWORD=${SSH_PASSWORD} \
    --build-arg CONTAINER_HOSTNAME=${CONTAINER_HOSTNAME} \
    -f Dockerfile .

echo "Done."
echo "SSH username: $SSH_USER"
if [[ "0" == "$SSH_PROMPT_PASSWORD" ]]; then
    echo "SSH temp password: $SSH_PASSWORD"
fi