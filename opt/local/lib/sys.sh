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

  proctl initpath "$DAEMON" >/dev/null && {
    printf ">> Disabling %s\n" "$DAEMON"
    proctl enabled "$DAEMON" && proctl disable "$DAEMON"

    printf ">> Stopping %s\n" "$DAEMON"
    local PROGNAME=$( proctl progname "$DAEMON" )

    if [ "$PROGNAME" == "" ] ; then
      proctl stop "$DAEMON"
    else
      pidof "$PROGNAME" >/dev/null && proctl stop "$DAEMON"
    fi
  }

  return $SUCCESS
}


disable_stop_and_kill_daemon () {
  local FUN_NAME='disable_stop_and_kill_daemon'
  local FUN_ARG_NUM='1'

  check_num_arguments_equal_to "$FUN_NAME" "$FUN_ARG_NUM" "$#" || \
    exit $EXIT_FAILURE

  local DAEMON="$1"

  check_not_empty_arguments "$FUN_NAME" "$DAEMON" || \
    exit $EXIT_FAILURE

  proctl initpath "$DAEMON" >/dev/null && {
    printf ">> Disabling %s\n" "$DAEMON"
    proctl enabled "$DAEMON" && proctl disable "$DAEMON"

    printf ">> Stopping %s\n" "$DAEMON"
    local PROGNAME=$( proctl progname "$DAEMON" )

    if [ "$PROGNAME" == "" ] ; then
      proctl stop "$DAEMON"
    else
      pidof "$PROGNAME" >/dev/null && proctl stop "$DAEMON"
      pidof "$PROGNAME" >/dev/null && killall -9 "$PROGNAME"
    fi
  }

  return $SUCCESS
}


###
} # SYS_SH
###

