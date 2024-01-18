#!/bin/zsh -f

# Start a new docker container with an alpine running my etc
# This is intended for lightweight basic testing

set -e

error() {
  printf '%s\n' "$@"
  exit 1
}

usage() {
  error "Usage: ${ZSH_ARGZERO} [ -u|--user USERNAME ]" \
    "  USERNAME: create and run as given USERNAME" \
}

while [ $# -ne 0 ]
do
  case "${1:?}" in
    -h|--help)
      usage
      exit 0
      ;;
    -u|--user)
      [ $# -ge 2 ] || error "Option $1 requires argument"
      HALFYAK_USERNAME="${2:?}"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*)
      error "Unrecognized option: '${1}'"
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

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
  --env HALFYAK_ETC_GIT="${DOCKER_GIT_REPO}" \
  ${TERM_PROGRAM+--env} ${TERM_PROGRAM+"TERM_PROGRAM=${TERM_PROGRAM}"} \
  ${HALFYAK_USERNAME+--env} ${HALFYAK_USERNAME+"HALFYAK_USERNAME=${HALFYAK_USERNAME}"} \
  --hostname "dockerized-etc" \
  --volume "${HOST_APK_CACHE}:${DOCKER_APK_CACHE}" \
  --volume "${HOST_ENTRYPOINT}:${DOCKER_ENTRYPOINT}" \
  --volume "${HOST_GIT_REPO}:${DOCKER_GIT_REPO}" \
  alpine:latest
