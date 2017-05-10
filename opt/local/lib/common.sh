#!/bin/sh

###
[ -z "$COMMON_SH" ] && {
readonly COMMON_SH='common.sh'
###


. /opt/local/lib/commons/codes


error_message () {
  local STACK_TRACE="${STACK_TRACE% *}* $FUN_NAME"
  local MESSAGE="$1"

  printf '!! %s\n' 'Error' 1>&2
  for CUR_FUN in $STACK_TRACE ; do
    printf '-> %s\n' "$CUR_FUN" 1>&2
  done
  printf '   : %s\n' "$MESSAGE" 1>&2

  return $SUCCESS
}


debug_message () {
  local MESSAGE="$1"

  if [ ! -z "$DEBUG" ] ; then
    printf '@@ %s\n' "$MESSAGE" 1>&2
  fi

  return $SUCCESS
}


info_message () {
  local MESSAGE="$1"

  printf ">> %s : %s\n" "$FUN_NAME" "$MESSAGE"

  return $SUCCESS
}


check_num_arguments_equal_to () {
  local FUN_NAME='check_num_arguments_equal_to'
  local FUN_ARG_NUM='2'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  if [ "$#" -ne "$FUN_ARG_NUM" ] ; then
    error_message "number of arguments must be equal to $FUN_ARG_NUM"
    exit $EXIT_FAILURE
  fi

  local REQ_ARG_NUM="$1"
  local CUR_ARG_NUM="$2"

  if [[ -z "$REQ_ARG_NUM" || -z "$CUR_ARG_NUM" ]] ; then
    error_message "an argument is an empty string"
    exit $EXIT_FAILURE
  fi

  if [ "$CUR_ARG_NUM" -ne "$REQ_ARG_NUM" ] ; then
    error_message "number of arguments must be equal to $REQ_ARG_NUM"
    return $FAILURE
  fi

  return $SUCCESS
}


check_num_arguments_at_least () {
  local FUN_NAME='check_num_arguments_at_least'
  local FUN_ARG_NUM='2'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  if [ "$#" -ne "$FUN_ARG_NUM" ] ; then
    error_message "number of arguments must be equal to $FUN_ARG_NUM"
    exit $EXIT_FAILURE
  fi

  local REQ_ARG_NUM="$1"
  local CUR_ARG_NUM="$2"

  if [[ -z "$REQ_ARG_NUM" || -z "$CUR_ARG_NUM" ]] ; then
    error_message "an argument is an empty string"
    exit $EXIT_FAILURE
  fi

  if [ "$CUR_ARG_NUM" -lt "$REQ_ARG_NUM" ] ; then
    error_message "number of arguments must be greater than or equal to $REQ_ARG_NUM"
    return $FAILURE
  fi

  return $SUCCESS
}


check_not_empty_arguments () {
  local FUN_NAME='check_not_empty_arguments'
  local FUN_ARG_NUM='1'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_at_least "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local CUR_ARG=''
  while [ "$#" -gt 0 ] ; do
    CUR_ARG="$1"
    shift 1
    if [ -z "$CUR_ARG" ] ; then
      error_message "an argument is an empty string"
      return $FAILURE
    fi
  done
  unset CUR_ARG

  return $SUCCESS
}


variable_is_read_only () {
  local FUN_NAME='variable_is_read_only'
  local FUN_ARG_NUM='1'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_equal_to "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local VARIABLE_NAME="$1"

  check_not_empty_arguments "$VARIABLE_NAME" \
    || exit $EXIT_FAILURE

  readonly | grep -q " ${VARIABLE_NAME}="

  return $?
}


variable_is_initialized () {
  local FUN_NAME='variable_is_initialized'
  local FUN_ARG_NUM='1'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_equal_to "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local VARIABLE_NAME="$1"

  check_not_empty_arguments "$VARIABLE_NAME" \
    || exit $EXIT_FAILURE

  set | grep -q "^${VARIABLE_NAME}="

  return $?
}


check_variable_value () {
  local FUN_NAME='check_variable_value'
  local FUN_ARG_NUM='2'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_equal_to "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local VARIABLE_NAME="$1"
  local VARIABLE_VALUE="$2"

  check_not_empty_arguments "$VARIABLE_NAME" \
    || exit $EXIT_FAILURE

  if ! variable_is_initialized "$VARIABLE_NAME" ; then
    return $FAILURE
  fi

  local CUR_VALUE="\$$VARIABLE_NAME"
  CUR_VALUE=`eval printf "$CUR_VALUE"`

  if [ "$CUR_VALUE" != "$VARIABLE_VALUE" ] ; then
    return $FAILURE
  fi

  return $SUCCESS
}


initialize_constant () {
  local FUN_NAME='initialize_constant'
  local FUN_ARG_NUM='2'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_equal_to "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local VARIABLE_NAME="$1"
  local VARIABLE_VALUE="$2"

  check_not_empty_arguments "$VARIABLE_NAME" \
    || exit $EXIT_FAILURE

  if ! variable_is_initialized "$VARIABLE_NAME" ; then
    eval readonly "${VARIABLE_NAME}=${VARIABLE_VALUE}"
    return $SUCCESS
  fi

  if ! variable_is_read_only "$VARIABLE_NAME" ; then
    eval readonly "${VARIABLE_NAME}=${VARIABLE_VALUE}"
    return $SUCCESS
  fi

  if check_variable_value "$VARIABLE_NAME" "$VARIABLE_VALUE" ; then
    return $SUCCESS
  fi

  return $FAILURE
}


initialize_multiple_constants () {
  local FUN_NAME='initialize_multiple_constants'
  local FUN_ARG_NUM='0'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_equal_to "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local VARIABLE_NAME=''
  local VARIABLE_VALUE=''
  local DEFINITION=''
  local RESULT=$SUCCESS

  while read DEFINITION ; do
    printf '%s\n' "$DEFINITION" | grep -qE '^[[:blank:]]*$' && continue

    VARIABLE_NAME="${DEFINITION%%=*}"
    VARIABLE_VALUE="${DEFINITION#*=}"

    initialize_constant "${VARIABLE_NAME}" "${VARIABLE_VALUE}" \
      || printf "### ${VARIABLE_NAME} ${VARIABLE_VALUE}\n"
    if [[ "$RESULT" -eq "$SUCCESS" && "$?" -ne "$SUCCESS" ]] ; then
      RESULT="$FAILURE"
      break
    fi
  done
  unset DEFINITION

  return $RESULT
}


load_lib () {
  local FUN_NAME='load_lib'
  local FUN_ARG_NUM='1'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_equal_to "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local LIBRARY_PATH="$1"

  check_not_empty_arguments "$LIBRARY_PATH" \
    || exit $EXIT_FAILURE

  if [ ! -f "$LIBRARY_PATH" ] ; then
    error_message "$LIBRARY_PATH is not a file"
    return $FAILURE
  fi

  local LIBRARY_NAME="${1##*/}"

  debug_message "loading $LIBRARY_NAME"

  if ! . "$LIBRARY_PATH" ; then
    error_message "$LIBRARY_PATH has not been loaded correctly"
    return $FAILURE
  fi

  return $SUCCESS
}


load_all_libs () {
  local FUN_NAME='load_all_libs'
  local FUN_ARG_NUM='0'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_equal_to "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local LIBS_TO_LOAD=`find "${OPTLOCAL}/lib/" -mindepth 1 -maxdepth 1 -type f \( -name \*.sh -a \! -name \*.off \)`

  if [ -z "$LIBS_TO_LOAD" ] ; then
    return $SUCCESS
  fi

  local BOOTSTRAP_LIBRARY=''
  for BOOTSTRAP_LIBRARY in $LIBS_TO_LOAD ; do
    load_lib "$BOOTSTRAP_LIBRARY" \
      || return $FAILURE
  done
  unset BOOTSTRAP_LIBRARY

  return $SUCCESS
}


common_sh_init () {
  initialize_multiple_constants \
      < /opt/local/lib/commons/codes \
    || return $FAILURE

  initialize_multiple_constants \
      < /opt/local/lib/commons/paths \
    || return $FAILURE

  . /opt/local/lib/commons/shell \
    || return $FAILURE

  return $SUCCESS
}


###
common_sh_init ; unset common_sh_init
debug_message "$COMMON_SH included"
} || true
###

