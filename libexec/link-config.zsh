#!/bin/zsh

# Symlink configuration into a required location

# zsh specific because we want zstat from zsh/stat

set -e

targetPrefix="${1:?}"
sourcePattern="${2:?}"

zmodload -F zsh/stat b:zstat

needSudo() {
  local targetDir="${1:?}"
  if [[ ! -w "${targetDir}" ]] && [[ -z "${SUDO}" ]]
  then
    print -- "Target directory '${targetDir}' not writable, will try sudo."
    print -- "You might get asked for your password"
    return 0
  else
    return 1
  fi
}

SUDO=
targetDir="${targetPrefix%/*}"

if [[ ! -d "${targetDir}" ]]
then
  print -- "Target directory '${targetDir}' does not exit"
  exit 1
else
  for sourceFile in ${~sourcePattern}
  do
    # It's tempting to try to flatten the link a bit, but i've previously reused this logic for links
    # into homebrew things where you cannot fully flatten because this will freeze in installed versions
    targetFile="${targetPrefix}${sourceFile:t}"
    if [[ -h "${targetFile}" ]]
    then
      current="$(zstat +link "${targetFile}")"
      if [[ ! "${sourceFile}" == "${current}" ]]
      then
        print -- "${targetFile} -> ${current} != ${sourceFile}"
        # else it already points to the right place
      fi
    elif [[ -e "${targetFile}" ]]
    then
      print -r -- "${targetFile} is not a link"
    else
      # it doesn't exist, set it up
      needSudo "${targetDir}" && { SUDO=sudo }
      ${SUDO-} ln -s "${sourceFile}" "${targetFile}"
      print -r -- "${targetFile} -> ${sourceFile}"
    fi
  done

  for targetFile in "${targetPrefix}"*(N@)
  do
    current="$(zstat +link "${targetFile}")"
    # Only remove links that match our source pattern, and test this first since it doesn't need to
    # check the filesystem
    if [[ ( "${current}" == ${~sourcePattern} ) && ( ! -e ${current} ) ]]
    then
      needSudo "${targetDir}" && { SUDO=sudo }
      print -- "${targetFile} is dangling -> ${current}"
      print -- "  :; rm ${targetFile}"
      ${SUDO-} rm -i "${targetFile}"
    fi
  done
fi
