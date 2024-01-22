#!/bin/zsh -f
# Driver for saving history to a sqlite database and querying it
# This script is invoked from zshaddhistory_functions, so use -f to reduce overhead
# If it becomes noticeable that part could be made into a shell function

set -e

history_database="${1:?}"
history_verb="${2:?}"
shift 2

LOG_STEM="${HOME}/var/log/halfyak-etc-sqlite-history"
LOG_OUT="${LOG_STEM}.out"
LOG_ERR="${LOG_STEM}.err"

sqlite_log() {
  printf '%s\n' "$@" 1>&2
}

sqlite_error() {
  sqlite_log "$@"
  exit 1
}

sqlite_history() {
  if [[ ! -e "${history_database}" ]]
  then
    # I couldn't find a way to get the print -P '%x' correctly quoted, even using an intermediate
    # variable. I suspect its prompt expansion, based on testing, and even '-f %q' doesn't help. This
    # form works for the case I envisage in practice (i.e. spaces in path segments in the absolute path).
    sqlite_log "Warning - no sqlite history database at ${(q+)history_database}, try:" \
      ":; '${$(print -P '%x'):A}' ${(q+)history_database} init"
  else
    sqlite3 -batch -echo "${history_database}" "$@"
  fi
}

sqlite_escape() {
  # The quote doubling here is for Sqlite escaping, see https://www.sqlite.org/lang_expr.html
  printf '%s' "${@//'/''}"
}

sqlite_history_select() {
  sqlite_history<<END_SQL
    SELECT
      ': ' || datetime(timestamp, 'unixepoch', 'localtime') || ' \"' || pwd || '\" ' || session || ' ;' || char(10)
        || ':; ' || command || char(10)
    FROM raw_history
    $(printf '%s\n' "$@")
    ;
END_SQL
}

sqlite_history_select_where_like() {
  local column="${1:?}"
  shift
  # Join and surround with % for convenient multiterm LIKE, then escape for SQL
  local escaped_args="$(sqlite_escape "%${(j:%:)@}%")"
  sqlite_history_select "WHERE ${column} LIKE '${escaped_args}'"
}

sqlite_history_verb_init() {
  local expect_schema='CREATE TABLE raw_history(command text, pwd text, timestamp integer, session text);'
  if [[ -e "${history_database}" ]]
  then
      actual_schema="$(sqlite_history .schema)"
      if [[ "${actual_schema}" != "${expect_schema}" ]]
      then
        # Use zstat from zsh/stat to get the file size here, since stat is not portable MacOS/alpine
        zmodload -F zsh/stat b:zstat
        sqlite_error 'Schema mismatch' \
          "   Actual: ${actual_schema}" \
          "   Expect: ${expect_schema}" \
          "   If you don't mind losing $(zstat +size "${history_database}") bytes of data:" \
          ":; rm ${(q+)history_database}"
      # else schema matches - all good
      fi
  else
    sqlite_log 'No database found, creating...'
    # Ensure the DB is created since sqlite_history checks for the file
    # We are assuming here that an empty file is a legit DB - this works as at
    # :; sqlite3 --version
    # 3.39.5 2022-10-14 20:58:05 554764a6e721fab307c63a4f98cd958c8428a5d9d8edfde951858d6fd02daapl
    mkdir -p "${history_database:h}"
    touch "${history_database}"
    sqlite_history <<<"${expect_schema}"
    sqlite_log 'Database created'
  fi
}

sqlite_history_verb_save() {
  local session_id="${1:?}"
  local history_line="${2:?}"
  if [[ "${history_line[1]}" == ' ' ]]
  then
    # Starts with space, skip the line, and get history to skip it also
    false
  else
    # Trim the trailing newline from the command line, then escape for SQL
    local escaped_line="$(sqlite_escape "${history_line%$'\n'}")"
    local escaped_pwd="$(sqlite_escape "${PWD}")"
    local escaped_session="$(sqlite_escape "${session_id}")"
    local sql="INSERT INTO raw_history VALUES ('${escaped_line}', '${escaped_pwd}', strftime('%s'), '${escaped_session}')"
    # Debugging - uncomment to save recent stuff
    # local debug_out="${LOG_OUT}"
    # Save to the db suppressing stdout unless debugging, but put stderr in LOG_ERR always
    # Error code is ignored so that regular shell history still works.
    sqlite_history 1>>"${debug_out-/dev/null}" 2>>"${LOG_ERR}" <<<"${sql}" || true
  fi
}

sqlite_history_verb_directory() {
  sqlite_history_select_where_like pwd "$@"
}

sqlite_history_verb_command() {
  sqlite_history_select_where_like command "$@"
}

sqlite_history_verb_session() {
  if [[ "$#" -ne 1 ]]
  then
    sqlite_error "Usage: $0 SESSION_ID\n"
  else
    local session_id="${1:?}"
    if [[ "${session_id}" =~ [^0-9A-F-] ]]
    then
      sqlite_error "SESSION_ID must contain only 0-9A-F-\n"
    else
      sqlite_history_select "WHERE session = '${session_id}'"
    fi
  fi
}

sqlite_history_verb_${history_verb} "$@"
