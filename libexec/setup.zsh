#!/bin/zsh

# This is an idempotent setup script

set -e

# :h:h removes libexec/setup.zsh and is the etc root.
# While this could be $(git rev-parse --absolute-git-dir), i want
# to avoid requiring git for setup.zsh to function correctly
ETC_DIR="${$(print -P '%x'):A:h:h}"

# Standard directories i want
mkdir -p ~/src
mkdir -p ~/tmp

# Link configuration with fixed locations

# This re-relativizes the absolute path to the dotfiles directory with respect
# to ~, so that the links are relative if possible. If not, it will fall back to absolute.
# Keeping them relative makes mounting them into docker containers easier
noglob "${ETC_DIR}"/libexec/link-config.zsh ~/. "${ETC_DIR#${HOME:A}/}"/dotfiles/*
