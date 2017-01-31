#!/usr/bin/env bash

function getVar() {
    VAR=${!1}
    if [[ "" == "${VAR}" ]]; then
        echo "Missing variable: ${1}" 1>&2
        exit 1
    fi
    echo ${VAR}
}

function includeConfig() {
    ENV=$(getVar "ENV")
    WORK_DIR=$(getVar "WORK_DIR")
    ARG_WORK_DIR=$(getVar "ARG_WORK_DIR")
    CONFIG_FILE="${WORK_DIR}/config/params.sh"
    if [[ ! -r "${CONFIG_FILE}" ]]; then
        echo "Error: ${ARG_WORK_DIR}/config/params.sh file not found" 1>&2
        exit 1
    fi
    . "${CONFIG_FILE}"
    ENV_CONFIG_FILE="${WORK_DIR}/config/env/${ENV}/params.sh"
    if [[ -r "${ENV_CONFIG_FILE}" ]]; then
        . "${ENV_CONFIG_FILE}"
    fi
}

function ctlActionScript() {
    WORK_DIR=$(getVar "WORK_DIR")
    SCRIPT="${WORK_DIR}/ctl/${1}.sh"
    if [[ ! -x "${SCRIPT}" ]]; then
        echo "No executable control script found: ${SCRIPT}" 1>&2
        exit 1
    fi
    . "${SCRIPT}"
}

function getCacheDir() {
    CACHE_DIR=$(getVar "CACHE_DIR")
    echo "${CACHE_DIR}"
}

function touchCacheDir() {
    CACHE_DIR=$(getCacheDir)
    mkdir -p "${CACHE_DIR}"
    echo "${CACHE_DIR}"
}

function getSshPasswordCacheFilePath() {
    CONTAINER_NAME=$(getVar "CONTAINER_NAME")
    FILE=$(slugifyVariableName ${CONTAINER_NAME})_ssh_password
    FILE="$(touchCacheDir)/${FILE}"
    echo "${FILE}"
}

function readSshPasswordCacheFile() {
    FILE=$(getSshPasswordCacheFilePath)
    echo $(cat "${FILE}")
}