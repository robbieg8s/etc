#!/bin/zsh

# This is an idempotent setup script

set -e

ETC_DIR="${$(print -P '%x'):A:h:h}"

# Standard directories i want
mkdir -p ~/src
mkdir -p ~/tmp

# Link configuration with fixed locations
noglob "${ETC_DIR}"/libexec/link-config.zsh ~/. "${ETC_DIR}"/dotfiles/*
