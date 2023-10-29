#!/bin/sh

set -e

# Configure container

# The apks add below can intermittently with
# WARNING: opening from cache https://dl-cdn.alpinelinux.org/alpine/v3.18/main: No such file or directory
# if run immediately after a cache clear.

ln -fns /var/cache/apk /etc/apk/cache
apk add git
apk add sudo
apk add zsh

# Clone config, assumes ETC_GIT set by dockerized-etc.zsh
cd
git clone "${ETC_GIT}"
~/etc/libexec/setup.zsh

# Start a configured shell
exec zsh
