#!/bin/zsh

# This is an idempotent setup script

set -e

## Phase One

# Note that in a clean install, no dotfiles are yet present. So the first commands cannot
# rely on variables set in zshenv etc.

# :h:h removes libexec/setup.zsh and is the etc root.
# While this could be $(git rev-parse --absolute-git-dir), i want
# to avoid requiring git for setup.zsh to function correctly
ETC_DIR="${$(print -P '%x'):A:h:h}"

# Keep bin in etc for less repo management overhead
ln -fns ~/etc/bin ~/bin

# Standard directories i want
mkdir -p ~/src
mkdir -p ~/tmp
mkdir -p ~/var/log

# Link configuration with fixed locations

# This re-relativizes the absolute path to the dotfiles directory with respect
# to ~, so that the links are relative if possible. If not, it will fall back to absolute.
# Keeping them relative makes mounting them into docker containers easier
noglob "${ETC_DIR}"/libexec/link-config.zsh ~/. "${ETC_DIR#${HOME:A}/}"/dotfiles/*

## Phase Two

# Now that dotfiles are linked, we can do more. However, this shell didn't get a chance to
# read zshenv in particular, so hand off to another shell for that bit. Don't source it,
# because we want to ensure the shell can find and read it by now.
exec "${ETC_DIR}"/libexec/setup-phase-two.zsh
