#!/usr/bin/env bash

set -e

LIBS_DIR="/opt/maciej-sz/bash-scripts"; if [[ ! -r "$LIBS_DIR" ]]; then echo "Installing Bash libs..."; sudo git clone https://github.com/maciej-sz/bash-scripts.git "$LIBS_DIR/"; fi
. "$LIBS_DIR/lib/read-val-if-not-empty.sh"
. "$LIBS_DIR/lib/prompt-yes-no.sh"

TARGET_DIR=""
IMAGE_NAME=""
PARENT_IMAGE_NAME=""
PARENT_IMAGE_TAG=""
CONTAINER_NAME=""

while test ${#} -gt 0
do
    param=$1
    IFS="=" read -r -a parts <<< "$1"
    shift
    arg_name=${parts[0]}
    arg_val=${parts[1]}
    case ${arg_name} in
        --target-dir)
            TARGET_DIR=${arg_val}
            continue;;
        --image-name)
            IMAGE_NAME=${arg_val}
            continue;;
        --container-name)
            CONTAINER_NAME=${arg_val}
            continue;;
        --parent-image-name)
            PARENT_IMAGE_NAME=${arg_val}
            continue;;
        --parent-image-tag)
            PARENT_IMAGE_TAG=${arg_val}
            continue;;
        *)
            echo "ERROR: Unrecognized parameter: $arg_name" 1>&2
            exit 1
    esac
done

function readSlashTail() {
    NAME=$1
    MSG=$2
    DEFAULT=$3

    if [[ "" != "${DEFAULT}" ]]; then MSG="${MSG} (default: ${DEFAULT})"; fi
    IFS="/" read -r -a PARTS <<< "${NAME}"
    if [[ 2 != ${#PARTS[@]} ]]; then
        while true; do
            read -p "${MSG}: " NAME;
            IFS="/" read -r -a PARTS <<< "${NAME}"
            if [[ 2 == ${#PARTS[@]} ]]; then
                break
            elif [[ "" == "${NAME}" && "" != "${DEFAULT}" ]]; then
                echo ${DEFAULT}
                break
            else
                echo "Name must contain slash"
            fi
        done
    fi
    echo ${NAME}
}

function getSlashNameTail() {
    IFS="/" read -r -a PARTS <<< "${1}"
    echo "${PARTS[1]}"
}

if [[ "" == "${TARGET_DIR}" ]]; then echo "Error: missing --target-dir parameter" 1>&2; exit 1; fi
if [[ "" == "${CONTAINER_NAME}" ]]; then read -p "Container name (eg. acme_ubuntu_jenkins): " CONTAINER_NAME; fi

IMAGE_NAME=$(readSlashTail "${IMAGE_NAME}" "Image tag (eg. acme/ubuntu-jenkins)")
IMAGE_NAME_TAIL=$(getSlashNameTail ${IMAGE_NAME})

PARENT_IMAGE_NAME=$(readSlashTail "${PARENT_IMAGE_NAME}" "Parent image name" "oxio/ubuntu-base")
PARENT_IMAGE_TAIL=$(getSlashNameTail ${PARENT_IMAGE_NAME})
PARENT_IMAGE_TAG=$(readValIfNotEmpty "Parent image tag" "${PARENT_IMAGE_TAG}" "latest")

PROJECT_DIR="$(pwd)/${TARGET_DIR}"
SOURCE_DIR="$(dirname $(readlink -f $0))/../project-structure"

if [[ "" != $(ls -A "${PROJECT_DIR}") ]]; then
    if [ ! $(promptyn "The directory \"${PROJECT_DIR}\" is not empty! Override?") ]; then
        exit
    else
        echo "Overriding."
    fi
fi

ENTRYPOINT_FILE="entrypoint_${IMAGE_NAME_TAIL}.sh";
ENTRYPOINT_REL_FILE="scripts/${ENTRYPOINT_FILE}"
ENTRYPOINT_ABS_FILE="${PROJECT_DIR}/${ENTRYPOINT_REL_FILE}"

ENTRYPOINT_SERVICES_FILE="entrypoint_${IMAGE_NAME_TAIL}_services.sh"
ENTRYPOINT_REL_SERVICES_FILE="scripts/${ENTRYPOINT_SERVICES_FILE}"
ENTRYPOINT_ABS_SERVICES_FILE="${PROJECT_DIR}/${ENTRYPOINT_REL_SERVICES_FILE}"

mkdir -p "${PROJECT_DIR}"
rsync -avzP "${SOURCE_DIR}/" "${PROJECT_DIR}/"

echo >> "${PROJECT_DIR}/config/script_params.sh"
echo "DOCKER_IMAGE_NAME=\"${IMAGE_NAME}\"" >> "${PROJECT_DIR}/config/script_params.sh"
echo "DOCKER_CONTAINER_NAME=\"${CONTAINER_NAME}\"" >> "${PROJECT_DIR}/config/script_params.sh"

echo >> "${PROJECT_DIR}/config/build_params.sh"
echo "DOCKER_CONTAINER_HOSTNAME=\"${IMAGE_NAME_TAIL}\"" >> "${PROJECT_DIR}/config/build_params.sh"

mkdir -p "${PROJECT_DIR}/scripts"
touch "${ENTRYPOINT_ABS_FILE}"
touch "${ENTRYPOINT_ABS_SERVICES_FILE}"
chmod +x "${ENTRYPOINT_ABS_FILE}"
chmod +x "${ENTRYPOINT_ABS_SERVICES_FILE}"

echo "#!/usr/bin/env bash" > "${ENTRYPOINT_ABS_FILE}"
echo ". /opt/docker-scripts/entrypoint_${IMAGE_NAME_TAIL}_services.sh" >> "${ENTRYPOINT_ABS_FILE}"
echo ". /opt/docker-scripts/entrypoint_common-daemon.sh" >> "${ENTRYPOINT_ABS_FILE}"

echo "#!/usr/bin/env bash" > "${ENTRYPOINT_ABS_SERVICES_FILE}"
echo ". /opt/docker-scripts/entrypoint_${PARENT_IMAGE_TAIL}_services.sh" >> "${ENTRYPOINT_ABS_SERVICES_FILE}"

DOCKERFILE="${PROJECT_DIR}/Dockerfile"
touch "${DOCKERFILE}"
echo "FROM ${PARENT_IMAGE_NAME}:${PARENT_IMAGE_TAG}" > "${DOCKERFILE}"
echo "COPY ${ENTRYPOINT_REL_FILE} /opt/docker-scripts/" >> "${DOCKERFILE}"
echo "COPY ${ENTRYPOINT_REL_SERVICES_FILE} /opt/docker-scripts/" >> "${DOCKERFILE}"
echo "ARG SSH_USER" >> "${DOCKERFILE}"
echo "ARG SSH_PASSWORD" >> "${DOCKERFILE}"
echo "RUN if [[ \"\" == \$(id -u \"\${SSH_USER}\") ]]; then useradd \"\$SSH_USER\" --shell /bin/bash --create-home; fi" >> "${DOCKERFILE}"
echo "RUN echo \"\${SSH_USER}:\${SSH_PASSWORD}\" | chpasswd" >> "${DOCKERFILE}"
echo "RUN gpasswd -a \"\$SSH_USER\" sudo" >> "${DOCKERFILE}"
echo "ENTRYPOINT exec /bin/bash -C '/opt/docker-scripts/${ENTRYPOINT_FILE}';" >> "${DOCKERFILE}"

echo "Project ${IMAGE_NAME} initialized."