#!/usr/bin/env bash

set -e

function show_usage() {
    echo "Usage: $(basename $0) [--force] targetdir source"
}

TARGET_DIR=""
SOURCE_REPO=""
SOURCE_DIR=""
SOURCE=""
FORCE=0

echo ${@}

while test ${#} -gt 0
do
    param=$1
    IFS="=" read -r -a parts <<< "$1"
    shift
    arg_name=${parts[0]}
    arg_val=${parts[1]}
    case ${arg_name} in
        --force)
            FORCE=1
            continue;;
        -*)
            echo $(show_usage) 1>&2
            exit 1
            continue;;
        *)
            if [[ "" == "${TARGET_DIR}" ]]; then
                TARGET_DIR=${param}
            elif [[ "" == "${SOURCE}" ]]; then
                SOURCE=${param}
            else
                echo $(show_usage) 1>&2
                exit 1
            fi
            continue;;
    esac
done

case ${SOURCE} in
    ssh:*|http:*)
        SOURCE_REPO=${SOURCE};;
    *)
        SOURCE_DIR=${SOURCE};;
esac

if [[ "" != "${SOURCE_REPO}" ]]; then
    SOURCE_DIR="/tmp/dockerctl-cache/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
    mkdir -p "${SOURCE_DIR}"
    cd "${SOURCE_DIR}"
    git clone "${SOURCE_REPO}" .
    cd "${PWD}"
elif [[ "" == "${SOURCE_DIR}" ]]; then
    echo $(show_usage) 1>&2
    exit 1
fi

if [[ ! -w "${TARGET_DIR}" ]]; then
    mkdir -p "${TARGET_DIR}"
elif [[ "0" == "${FORCE}" && "" != "$(ls -A ${TARGET_DIR})" ]]; then
    echo "ERROR: Target directory is not empty: ${TARGET_DIR}" 1>&2
    exit 1
fi

echo "Source: $SOURCE_DIR, target: $TARGET_DIR"

DIRS=(ctl config scripts data)
for i in "${DIRS[@]}"
do
    mkdir -p "${TARGET_DIR}/${i}"
    rsync -avzP "${SOURCE_DIR}/${i}/" "${TARGET_DIR}/${i}/"
done
