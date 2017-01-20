#!/usr/bin/env bash

./stop.sh >/dev/null 2>&1 &

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
                *)
                    continue;;
            esac
            continue;;
        --R*)
            START_ARGS="$START_ARGS --${param:3}"
            case ${arg_name} in
                --Rssh-port)
                    SSH_PORT=${arg_val}
                    continue;;
                *)
                    continue;;
            esac
            continue;;
        --login)
            LOGIN=1
            continue;;
        *)
            echo "ERROR: Unrecognized parameter: $arg_name" 1>&2
            exit 1
    esac
done

./build.sh \
    ${BUILD_ARGS}
echo "Waiting for old container to stop..."
wait
./start.sh \
    ${START_ARGS}

if [[ "" != "${SSH_PORT}" ]]; then
    echo "Removing entry from known_hosts..."
    ssh-keygen -f "~/.ssh/known_hosts" -R [localhost]:"${SSH_PORT}"
fi

if [[ "1" == "${LOGIN}" ]]; then
    echo "Logging in..."
    if [[ "" == "${SSH_USER}" || "" == "${SSH_PORT}" ]]; then
        echo "ERROR: Cannot login: user or port not provided" 1>&2
        exit 1
    fi
    sleep 1
    ssh -p "${SSH_PORT}" "${SSH_USER}@localhost"
fi