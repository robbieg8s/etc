#!/bin/zsh

set -e

# General test infra, probably extractable

this_script="${$(print -P '%x'):A}"
test_base="${this_script%/test/*}"
test_offset="${this_script##*/test/}"
script_under_test="${test_base}/${test_offset:h}/${${test_offset:t}#test-}"

colored() {
  local color="${1:?}"
  shift
  print -P "%F{${color}}$@%f"
}

green() {
  colored green "$@"
}

red() {
  colored red "$@"
}

failed() {
  local test_name="${1:?}"
  local test_location="${2:?}"
  printf '%s: Test %s at %s\n' "$(red "TEST FAILED")" "$(green "${test_name}")" "${test_location}"
  shift 2
  printf '%s\n' "$@"
  printf 'Stdout:\n'
  cat "${output_dir}"/"${test_name}.out"
  printf 'Stderr:\n'
  cat "${output_dir}"/"${test_name}.err"
  exit 2
}


test_dir=$(mktemp -d)
output_dir="${test_dir}"/output
mkdir -p "${output_dir}"

cleanup() {
  case "$?" in
    0) green "PASSED" ;;
    *) red "FAILED" ;;
  esac
  rm -rf "${test_dir}"
}

trap 'cleanup ; trap - ERR EXIT' ERR EXIT
trap 'cleanup ; trap - INT ; kill -INT $$' INT

run_test_unchecked() {
  local test_name="${1:?}"
  shift
  # Clean up previous tests, so that accidental use of the wrong output is caught earlier
  rm -f "${output_dir}"/*.{out,err}(N)
  local stdout="${output_dir}/${test_name}.out"
  local stderr="${output_dir}/${test_name}.err"
  "${script_under_test}" "$@" 1>"${stdout}" 2>"${stderr}"
  return "$?"
  # Caller checks exit code, if they forget, set -e above will keep them honest
}

run_test() {
  local test_name="${1:?}"
  local test_location="${2:?}"
  shift 2
  run_test_unchecked "${test_name}" "$@" || {
    exit_code="$?"
    failed "${test_name}" "${test_location}" "Exit code ${exit_code} from ${script_under_test}"
  }
}

verify_stdout() {
  local test_name="${1:?}"
  local test_location="${2:?}"
  local expected_stdout="${3:?}"
  local actual_stdout="${output_dir}/${test_name}.out"
  # Check stdout
  diff "${expected_stdout}" "${actual_stdout}" || \
    failed "${test_name}" "${test_location}" "Actual output (>) differs from expected (<), diff above"
  # Don't verify stderr, assume that it's informational if exit code and output are ok
}

# From here down, it's likely specific to this test
# In general, the tests assume that the sort order of * is stable

verify_links() {
  local test_name="${1:?}"
  local test_location="${2:?}"
  local target_dir="${3:?}"
  shift 3
  diff =(printf '%s\n' "$@") =(
    for result in "${target_dir}"/*
    do
      readlink "${result}"
    done
  ) || {
    failed "${test_name}" "${test_location}" "Filesystem outcome (>) differs from expected (<), diff above"
  }
}

## Missing Target Directory

# If target is missing, expected to exit out with error message
run_test_unchecked missing "${test_dir}/missing target/" ignored-source && {
  failed missing "$(print -P '%x:%I')" "Should fail when target directory does not exist"
}
verify_stdout missing "$(print -P '%x:%I')" =(cat<<END_EXPECTED_MISSING
Target directory '${test_dir}/missing target' does not exist
END_EXPECTED_MISSING
)

## No Source files match pattern

mkdir "${test_dir}/target-empty"

# If nothing matches, expected nothing to happen (specifically, not an error)
mkdir "${test_dir}/empty-source"
run_test empty-source "$(print -P '%x:%I')" "${test_dir}/target-empty/" "${test_dir}/empty-source/*"
verify_stdout empty-source "$(print -P '%x:%I')" /dev/null

## Absolute links

absolute_fixture="${test_dir}/absolute/fixture"
mkdir -p "${absolute_fixture}"
touch "${absolute_fixture}/"{sail,salt,'say sweet',sunset}
mkdir "${test_dir}/target-absolute"

run_test absolute "$(print -P '%x:%I')" "${test_dir}/target-absolute/" "${absolute_fixture}/*"
verify_stdout absolute "$(print -P '%x:%I')" =(cat<<END_EXPECTED_ABSOLUTE
${test_dir}/target-absolute/sail -> ${absolute_fixture}/sail
${test_dir}/target-absolute/salt -> ${absolute_fixture}/salt
'${test_dir}/target-absolute/say sweet' -> '${absolute_fixture}/say sweet'
${test_dir}/target-absolute/sunset -> ${absolute_fixture}/sunset
END_EXPECTED_ABSOLUTE
)
verify_links absolute "$(print -P '%x:%I')" "${test_dir}/target-absolute" "${absolute_fixture}/"{sail,salt,'say sweet',sunset}
# Second run should silently make no changes
run_test absolute-again "$(print -P '%x:%I')" "${test_dir}/target-absolute/" "${absolute_fixture}/*"
verify_stdout absolute-again "$(print -P '%x:%I')" /dev/null
verify_links absolute-again "$(print -P '%x:%I')" "${test_dir}/target-absolute" "${absolute_fixture}/"{sail,salt,'say sweet',sunset}

## Relative links

mkdir "${test_dir}/target-relative"
mkdir -p "${test_dir}"/relative
cp -R "${absolute_fixture}" "${test_dir}"/relative

run_test relative "$(print -P '%x:%I')" "${test_dir}/target-relative/" "../relative/fixture/*"
verify_stdout relative "$(print -P '%x:%I')" =(cat<<END_EXPECTED_RELATIVE
${test_dir}/target-relative/sail -> ../relative/fixture/sail
${test_dir}/target-relative/salt -> ../relative/fixture/salt
'${test_dir}/target-relative/say sweet' -> '../relative/fixture/say sweet'
${test_dir}/target-relative/sunset -> ../relative/fixture/sunset
END_EXPECTED_RELATIVE
)
verify_links relative "$(print -P '%x:%I')" "${test_dir}/target-relative" ../relative/fixture/{sail,salt,'say sweet',sunset}
# Second run should silently make no changes
run_test relative-again "$(print -P '%x:%I')" "${test_dir}/target-relative/" "../relative/fixture/*"
verify_stdout relative-again "$(print -P '%x:%I')" /dev/null
verify_links relative-again "$(print -P '%x:%I')" "${test_dir}/target-relative" ../relative/fixture/{sail,salt,'say sweet',sunset}

## File prefix in source and target

mkdir "${test_dir}/target-prefixes"

run_test prefixes "$(print -P '%x:%I')" "${test_dir}/target-prefixes/re" "../relative/fixture/sa*"
verify_stdout prefixes "$(print -P '%x:%I')" =(cat<<END_EXPECTED_PREFIXES
${test_dir}/target-prefixes/resail -> ../relative/fixture/sail
${test_dir}/target-prefixes/resalt -> ../relative/fixture/salt
'${test_dir}/target-prefixes/resay sweet' -> '../relative/fixture/say sweet'
END_EXPECTED_PREFIXES
)
verify_links prefixes "$(print -P '%x:%I')" "${test_dir}/target-prefixes" ../relative/fixture/{sail,salt,'say sweet'}

## Handling of Dangling and Irrelevant links

# A stale link is reported with an option to fix
ln -s "../relative/fixture/split sport" "${test_dir}/target-relative/split sport"
# A link which doesn't match the source pattern just gets ignored
ln -s "another-location" "${test_dir}/target-relative/student strategy"
yes n | run_test stale-no "$(print -P '%x:%I')" "${test_dir}/target-relative/" "../relative/fixture/*"
verify_stdout stale-no "$(print -P '%x:%I')" =(cat<<END_EXPECTED_STALE_NO
'${test_dir}/target-relative/split sport' is dangling -> '../relative/fixture/split sport'
:; rm -- '${test_dir}/target-relative/split sport'
END_EXPECTED_STALE_NO
)
# Since we said n, it didn't happen
diff =(readlink "${test_dir}/target-relative/split sport") =(printf '../relative/fixture/split sport\n') || {
  failed stale-no "$(print -P '%x:%I')" "Link was unexpectedly removed"
}

yes y | run_test stale-yes "$(print -P '%x:%I')" "${test_dir}/target-relative/" "../relative/fixture/*"
# The complexity with the last line below is to suppress the trailing newline
verify_stdout stale-yes "$(print -P '%x:%I')" =(cat<<END_EXPECTED_STALE_YES
'${test_dir}/target-relative/split sport' is dangling -> '../relative/fixture/split sport'
:; rm -- '${test_dir}/target-relative/split sport'
END_EXPECTED_STALE_YES
)
# Since we said y, it did happen - we need to use -h since the link is dangling
[[ ! -h "${test_dir}/target-relative/split sport" ]] || {
  failed stale-yes "$(print -P '%x:%I')" "Link was not removed as expected"
}

## Handling of Existing Links and Files

# A link that looks like we didn't make it is warned about and untouched
rm "${test_dir}/target-relative/sail"
ln -s "another location" "${test_dir}/target-relative/sail"
# A file is warned about and untouched
rm "${test_dir}/target-relative/salt"
touch "${test_dir}/target-relative/salt"
run_test no-move-trounce "$(print -P '%x:%I')" "${test_dir}/target-relative/" "../relative/fixture/*"
verify_stdout no-move-trounce "$(print -P '%x:%I')" =(cat<<END_EXPECTED_NO_MOVE_TROUNCE
${test_dir}/target-relative/sail -> 'another location' != ../relative/fixture/sail
${test_dir}/target-relative/salt is not a link
END_EXPECTED_NO_MOVE_TROUNCE
)
diff =(readlink ${test_dir}/target-relative/sail) =(printf 'another location\n') || {
  failed no-move-trounce "$(print -P '%x:%I')" "Link was unexpectedly updated"
}
[[ -f ${test_dir}/target-relative/salt ]] || {
  failed no-move-trounce "$(print -P '%x:%I')" "Expected file is not a file"
}
