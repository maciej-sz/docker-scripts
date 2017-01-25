#!/usr/bin/env bash

. "$(dirname $0)/../config/script_params.sh"

echo -n "Stopping... "
docker stop ${DOCKER_CONTAINER_NAME}
echo -n "Rm... "
docker rm ${DOCKER_CONTAINER_NAME}