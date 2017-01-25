#!/usr/bin/env bash

set -e

STOP_SCRIPT="./$(dirname $0)/stop.sh"
BUILD_SCRIPT="./$(dirname $0)/build.sh"
START_SCRIPT="./$(dirname $0)/start.sh"

if [[ ! -x "${STOP_SCRIPT}" ]]; then echo "ERROR: Missing stop script" 1>&2; exit 2; fi
if [[ ! -x "${BUILD_SCRIPT}" ]]; then echo "ERROR: Missing build script" 1>&2; exit 2; fi
if [[ ! -x "${START_SCRIPT}" ]]; then echo "ERROR: Missing start script" 1>&2; exit 2; fi

"./${STOP_SCRIPT}" >/dev/null 2>&1 &

BUILD_ARGS=""
START_ARGS=""
SSH_USER=""
SSH_PORT=""
LOGIN=""

while test ${#} -gt 0
do
    param=$1
    IFS="=" read -r -a parts <<< "$1"
    shift
    arg_name=${parts[0]}
    arg_val=${parts[1]}
    case ${arg_name} in
        --B*)
            BUILD_ARGS="$BUILD_ARGS --${param:3}"
            case ${arg_name} in
                --Bssh-user)
                    SSH_USER=${arg_val}
                    continue;;
                --Bssh-port)
                    SSH_PORT=${arg_val}
                    continue;;
                *)
                    continue;;
            esac
            continue;;
        --R*)
            START_ARGS="$START_ARGS --${param:3}"
            continue;;
        --login)
            LOGIN=1
            continue;;
        *)
            echo "ERROR: Unrecognized parameter: $arg_name" 1>&2
            exit 1
    esac
done

. "${BUILD_SCRIPT}" \
    ${BUILD_ARGS}

echo "Waiting for old container to stop..."
wait

"./${START_SCRIPT}" \
    ${START_ARGS}

SSH_URL="[localhost]:${SSH_PORT}"

if [[ "" != "${SSH_PORT}" ]]; then
    echo "Removing entry from known_hosts..."
    ssh-keygen -f ~/.ssh/known_hosts -R "${SSH_URL}"
fi

if [[ "1" == "${LOGIN}" ]]; then
    echo "Logging in..."
    if [[ "" == "${SSH_USER}" || "" == "${SSH_PORT}" ]]; then
        echo "ERROR: Cannot login: user or port not provided" 1>&2
        exit 1
    fi
    if [[ "" = $(which sshpass) ]]; then
        echo "Installing sshpass (locally)...";
        sudo apt-get install -y sshpass;
    else
        sleep 1
    fi
    sshpass -p "${SSH_PASSWORD}" ssh -o StrictHostKeyChecking=no -p "${SSH_PORT}" "${SSH_USER}@localhost"
    echo "Good bye!"
fi