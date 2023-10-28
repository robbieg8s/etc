#!/bin/zsh

# Start a new docker container with an alpine running my etc
# This is intended for lightweight basic testing

set -e

ETC_DIR="${$(print -P '%x'):A:h:h}"
HOST_ENTRYPOINT="${ETC_DIR}/libexec/docker/entrypoint.sh"
HOST_GIT_REPO="${ETC_DIR}/.git"

CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/halfyak.org/etc"
HOST_APK_CACHE="${CACHE_DIR}/apk"

mkdir -p "${HOST_APK_CACHE}" "${HOST_ENTRYPOINT%/*}"

DOCKER_ENTRYPOINT="/mnt/entrypoint.sh"
DOCKER_GIT_REPO="/mnt/etc.git"

DOCKER_APK_CACHE="/var/cache/apk"

docker run --rm --interactive --tty \
  --entrypoint "${DOCKER_ENTRYPOINT}" \
  --env ETC_GIT="${DOCKER_GIT_REPO}" \
  --hostname "dockerized-etc" \
  --volume "${HOST_APK_CACHE}:${DOCKER_APK_CACHE}" \
  --volume "${HOST_ENTRYPOINT}:${DOCKER_ENTRYPOINT}" \
  --volume "${HOST_GIT_REPO}:${DOCKER_GIT_REPO}" \
  alpine:latest

