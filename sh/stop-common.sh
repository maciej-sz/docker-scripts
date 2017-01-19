#!/usr/bin/env bash

echo -n "Stopping... "
docker stop ${DOCKER_CONTAINER_NAME}
echo -n "Rm... "
docker rm ${DOCKER_CONTAINER_NAME}