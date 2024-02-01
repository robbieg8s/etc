#!/bin/false
# This script is intended to be sourced

() {
  # For iTerm, activate the FinalTerm shell integration
  # For details, see Shell Integration/FinalTerm on https://iterm2.com/documentation-escape-codes.html

  # Firstly, bracket our prompt with FTCS_PROMPT and FTCS_COMMAND_START
  # Remember $'...' expands print special characters in ...
  local ftcs_prompt=$'\e]133;A\a'
  local ftcs_command_start=$'\e]133;B\a'
  PS1="%{${ftcs_prompt}%}${PS1}%{${ftcs_command_start}%}"

  # Next, we need to use hooks around the command output - note the functions here are global

  # Before execution, FTCS_COMMAND_EXECUTED
  halfyak_etc_preexec_ftcs_command_executed() {
    print -n "\e]133;C\a"
  }
  preexec_functions=($preexec_functions halfyak_etc_preexec_ftcs_command_executed)

  # After execution, FTCS_COMMAND_FINISHED
  halfyak_etc_precmd_ftcs_command_finished() {
    # Include the exit code here for visual indication of command outcome
    print -n "\e]133;D;$?\r\a"
  }
  precmd_functions=($precmd_functions halfyak_etc_precmd_ftcs_command_finished)
}

() {
  # Display the current git branch name in the iterm badge, and the repository name and
  # branch in the window title. This is less clutter than in the prompt, and could in
  # principle be made more async (although i'm not sure about the ergonomics of that).
  # This
  halfyak_etc_precmd_iterm_badge_and_title() {
    local window_title=" "
    local badge=""
    local repository=""
    local location=""
    local gitroot="$(git rev-parse --show-toplevel 2>/dev/null)"
    if [[ ! -z "${gitroot}" ]]
    then
      repository="${gitroot##*/}"
      local symbolic="$(git symbolic-ref --quiet HEAD)"
      if [[ -z "${symbolic}" ]]
      then
        location="detached "$(git describe --always --all --contains HEAD)
      else
        # We appear to be on a branch
        location="${symbolic#refs/heads/}"
      fi
      window_title="(${repository})-[${location}]"
      # The user variable we render into the iterm badge via the iterm settings
      # Profiles/General/Basics/Badge is set to \(user.badge?)
      badge="$(base64 <<< "${location}")"
    fi
    # We want to update with empty strings here if we are not in a git repository

    # See https://iterm2.com/documentation-escape-codes.html under SetUserVar
    print -n "\e]1337;SetUserVar=badge=${badge}\a"
    # These are xterm sequences which iTerm respects. I feel like there should be a terminfo
    # sequence for these, but i have not been able to find it documented. These could be broader,
    # but it's convenient to do here and works for my use cases.
    # See https://www.xfree86.org/current/ctlseqs.html under Operating System Controls, Set Text Parameters
    # Set the tab title to the current named directory
    print -nP "\e]1;%-1~\a"
    # Set the window title to the git info (or empty) from above
    print -n "\e]2;${window_title}\a"
  }
  precmd_functions=($precmd_functions halfyak_etc_precmd_iterm_badge_and_title)
}
