#!/bin/sh

###
[ -z "$SHELL_SH" ] && {
readonly SHELL_SH='included'
###


. /opt/local/lib/common.sh


change_user_shell () {
  local FUN_NAME='change_user_shell'
  local FUN_ARG_NUM='2'

  check_num_arguments_equal_to "$FUN_NAME" "$FUN_ARG_NUM" "$#" || \
    exit $EXIT_FAILURE

  local _PASSWD_FILE='/etc/passwd'

  if [ ! -f "$_PASSWD_FILE" ] ; then
    printf '!!! %s\n' "$_PASSWD_FILE does not exist" 1>&2
    return $FAILURE
  fi

  local _USER="$1"
  local _SHELL="$2"

  check_not_empty_arguments "$FUN_NAME" "$_USER" "$_SHELL" || \
    exit $EXIT_FAILURE

  if ( ! grep -q -e "^${_USER}:" "$_PASSWD_FILE" ) ; then
    printf '!!! %s\n' "the user \"${_USER}\" does not exist" 1>&2
    return $FAILURE
  fi

  if [ -d "$_SHELL" ] ; then
    printf '!!! %s\n' "\"${_SHELL}\" is a directory" 1>&2
    return $FAILURE
  fi

  if [ ! -x "$_SHELL" ] ; then
    printf '!!! %s\n' "\"${_SHELL}\" is not executable" 1>&2
    return $FAILURE
  fi

  _SHELL=$( printf "$_SHELL" | sed -e 's-/-\\/-g' )

  sed -i -r -e "s/^(${_USER}:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:).*\$/\1${_SHELL}/" \
      "$_PASSWD_FILE"

  return $SUCCESS
}


###
} # SHELL_SH
###

