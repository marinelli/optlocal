#!/bin/sh

###
[ -z "$SYS_SH" ] && {
readonly SYS_SH='included'
###


. /opt/local/lib/common.sh


wait_for_seconds () {
  local FUN_NAME='wait_for_seconds'
  local FUN_ARG_NUM='1'

  check_num_arguments_equal_to "$FUN_NAME" "$FUN_ARG_NUM" "$#" || \
    exit $EXIT_FAILURE

  local SECONDS="$1"

  check_not_empty_arguments "$FUN_NAME" "$SECONDS" || \
    exit $EXIT_FAILURE

  printf ">> Waiting for %s seconds...\n" "$SECONDS"
  sleep "$SECONDS"

  return $?
}


disable_and_stop_daemon () {
  local FUN_NAME='disable_and_stop_daemon'
  local FUN_ARG_NUM='1'

  check_num_arguments_equal_to "$FUN_NAME" "$FUN_ARG_NUM" "$#" || \
    exit $EXIT_FAILURE

  local DAEMON="$1"

  check_not_empty_arguments "$FUN_NAME" "$DAEMON" || \
    exit $EXIT_FAILURE

  which "$DAEMON" >/dev/null && {
    printf ">> Disabling %s\n" "$DAEMON"
    pidof "$DAEMON" >/dev/null && proctl stop "$DAEMON"
    pidof "$DAEMON" >/dev/null && killall -9 "$DAEMON"
    proctl enabled "$DAEMON" && proctl disable "$DAEMON"
  }

  return $SUCCESS
}


###
} # SYS_SH
###

