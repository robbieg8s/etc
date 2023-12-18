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
