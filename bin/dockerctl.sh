#!/usr/bin/env bash

set -e

LIBS_DIR="/opt/maciej-sz/bash-scripts"; if [[ ! -r "$LIBS_DIR" ]]; then echo "Installing Bash libs..."; sudo git clone https://github.com/maciej-sz/bash-scripts.git "$LIBS_DIR/"; fi
. "$LIBS_DIR/lib/read-password.sh"
. "$LIBS_DIR/lib/slugify-variable-name.sh"

. "$(dirname $(realpath ${BASH_SOURCE[0]}))/../config/config.sh"
. "$(dirname $(realpath ${BASH_SOURCE[0]}))/../include/common.sh"

ENV=${HOSTNAME}

function show_usage() {
    echo "Usage: $(basename $0) [--env=environment] (init|build|start|stop|login|rebuild|cache-ssh-password|clear-cache) [directory] [arguments...]"
}

CTL_ACTION=""
ARG_WORK_DIR=""
SELF_ARGS=""
NEW_ARGS=""
while test ${#} -gt 0
do
    param=$1
    IFS="=" read -r -a parts <<< "$1"
    shift
    arg_name=${parts[0]}
    arg_val=${parts[1]}
    case ${arg_name} in
        --env)
            ENV=${arg_val}
            SELF_ARGS="${SELF_ARGS} --env=${ENV}"
            continue;;
        *)
            if [[ ${arg_name} =~ ^\-.* && "" == "${CTL_ACTION}" && "" == ${WORK_DIR} ]]; then
                echo $(show_usage) 1>&2
                exit 1
            fi
            if [[ "" == "${CTL_ACTION}" ]]; then
                case ${param} in
                    init|build|start|stop|login|rebuild|cache-ssh-password|clear-cache) CTL_ACTION=${param};;
                     *) echo $(show_usage) 2>&1; exit 1;;
                esac
            elif [[ "" == "${ARG_WORK_DIR}" ]]; then
                ARG_WORK_DIR=${param}
            else
                NEW_ARGS="${NEW_ARGS} ${param}"
            fi
            continue;;
    esac
done

if [[ "" == "${CTL_ACTION}" ]]; then
    echo $(show_usage) 2>&1
    exit 1
fi
if [[ "" == "${ARG_WORK_DIR}" ]]; then
    ARG_WORK_DIR="."
fi

set -- ${NEW_ARGS}

WORK_DIR="$(pwd)/${ARG_WORK_DIR}"
INCLUDE_CONFIG=1


case ${CTL_ACTION} in
    init)
        set -- "${ARG_WORK_DIR}" ${NEW_ARGS}
        . "$(dirname $(realpath ${BASH_SOURCE[0]}))/init.sh"
        ;;
    build|start)
        includeConfig
        SSH_PASSWORD=$(readSshPasswordCacheFile)
        ctlActionScript ${CTL_ACTION}
        ;;
    rebuild)
#        "${0}" ${SELF_ARGS} stop "${ARG_WORK_DIR}"; exit
        "${0}" ${SELF_ARGS} stop "${ARG_WORK_DIR}" >/dev/null 2>&1 &
        "${0}" ${SELF_ARGS} build "${ARG_WORK_DIR}"
        echo "Waiting for old container to stop..."
        wait
        "${0}" ${SELF_ARGS} start "${ARG_WORK_DIR}"
        ;;
    stop)
        includeConfig
        CONTAINER_NAME=$(getVar "CONTAINER_NAME")
        if [[ "" == "${CONTAINER_NAME}" ]]; then
            echo "Missing variable: DOCKER_CONTAINER_NAME" 1>&2
            exit 1
        fi
        echo "Stopping ${CONTAINER_NAME}... "
        docker stop "${CONTAINER_NAME}"
        echo "Removing ${CONTAINER_NAME}... "
        docker rm "${CONTAINER_NAME}"
        echo "Container stopped."
        ;;
    cache-ssh-password)
        includeConfig
        echo "$(readPassword)" > "$(getSshPasswordCacheFilePath)"
        echo -e "\Password cached."
        ;;
    clear-cache)
        rm -rf "$(getCacheDir)/"
        echo "Cache cleared."
        ;;
    login)
        includeConfig
        SSH_PORT=$(getVar "SSH_PORT")
        SSH_USER=$(getVar "SSH_USER")
        SSH_PASSWORD=$(readSshPasswordCacheFile)
        SSH_URL="[localhost]:${SSH_PORT}"
        echo "Removing entry from known_hosts..."
        ssh-keygen -f ~/.ssh/known_hosts -R "${SSH_URL}"
        echo "Logging in..."
        if [[ "" = $(which sshpass) ]]; then
            echo "Installing sshpass (locally)..."
            sudo apt-get install -y sshpass
        else
            sleep 1
        fi
        sshpass -p "${SSH_PASSWORD}" ssh -o StrictHostKeyChecking=no -p "${SSH_PORT}" "${SSH_USER}@localhost"
        echo "Logged out."
        ;;
    *)
        echo $(show_usage) 1>&2
        exit 1
        ;;
esac
