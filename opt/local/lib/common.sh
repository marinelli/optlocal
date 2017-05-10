#!/bin/sh

###
[ -z "$COMMON_SH" ] && {
readonly COMMON_SH='included'
###


check_num_arguments_equal_to () {
  local FUN_NAME='check_num_arguments_equal_to'
  local FUN_ARG_NUM='3'

  if [ "$#" -ne "$FUN_ARG_NUM" ] ; then
    printf '!! %s : %s\n' "$FUN_NAME" "number of arguments must $FUN_ARG_NUM" 1>&2
    exit 1
  fi

  local CALLER_FUN="$1"
  local REQ_ARG_NUM="$2"
  local CUR_ARG_NUM="$3"

  if [[ -z "$CALLER_FUN" || -z "$REQ_ARG_NUM" || -z "$CUR_ARG_NUM" ]] ; then
    printf '!! %s : %s\n' "$FUN_NAME" "an argument is an empty string" 1>&2
    exit 1
  fi

  if [ "$CUR_ARG_NUM" -ne "$REQ_ARG_NUM" ] ; then
    printf '!! %s : %s\n' "$CALLER_FUN" "number of arguments must $REQ_ARG_NUM" 1>&2
    return 1
  fi

  return 0
}


check_num_arguments_at_least () {
  local FUN_NAME='check_num_arguments_at_least'
  local FUN_ARG_NUM='3'

  if [ "$#" -ne "$FUN_ARG_NUM" ] ; then
    printf '!! %s : %s\n' "$FUN_NAME" "number of arguments must $FUN_ARG_NUM" 1>&2
    exit 1
  fi

  local CALLER_FUN="$1"
  local REQ_ARG_NUM="$2"
  local CUR_ARG_NUM="$3"

  if [[ -z "$CALLER_FUN" || -z "$REQ_ARG_NUM" || -z "$CUR_ARG_NUM" ]] ; then
    printf '!! %s : %s\n' "$FUN_NAME" "an argument is an empty string" 1>&2
    exit 1
  fi

  if [ "$CUR_ARG_NUM" -lt "$REQ_ARG_NUM" ] ; then
    printf '!! %s : %s\n' "$CALLER_FUN" \
      "number of arguments must be greater than or equal to $REQ_ARG_NUM" 1>&2
    return 1
  fi

  return 0
}


check_not_empty_arguments () {
  local FUN_NAME='check_not_empty_arguments'
  local FUN_ARG_NUM='2'

  check_num_arguments_at_least "$FUN_NAME" "$FUN_ARG_NUM" "$#" || exit 1

  local CALLER_FUN="$1"
  shift 1

  if [ -z "$CALLER_FUN" ] ; then
    printf '!! %s : %s\n' "$CALLER_FUN" "an argument is an empty string" 1>&2
    return 1
  fi

  local CUR_ARG=''
  while [ "$#" -gt 0 ] ; do
    CUR_ARG="$1"
    shift 1
    if [ -z "$CUR_ARG" ] ; then
      printf '!! %s : %s\n' "$CALLER_FUN" "an argument is an empty string" 1>&2
      return 1
    fi
  done
  unset CUR_ARG

  return 0
}


variable_is_read_only () {
  local FUN_NAME='variable_is_read_only'
  local FUN_ARG_NUM='1'

  check_num_arguments_equal_to "$FUN_NAME" "$FUN_ARG_NUM" "$#" || exit 1

  local VARIABLE_NAME="$1"

  check_not_empty_arguments "$FUN_NAME" "$VARIABLE_NAME" || exit 1

  readonly | grep -q " ${VARIABLE_NAME}="

  return $?
}


variable_is_initialized () {
  local FUN_NAME='variable_is_initialized'
  local FUN_ARG_NUM='1'

  check_num_arguments_equal_to "$FUN_NAME" "$FUN_ARG_NUM" "$#" || exit 1

  local VARIABLE_NAME="$1"

  check_not_empty_arguments "$FUN_NAME" "$VARIABLE_NAME" || exit 1

  set | grep -q "^${VARIABLE_NAME}="

  return $?
}


check_variable_value () {
  local FUN_NAME='check_variable_value'
  local FUN_ARG_NUM='2'

  check_num_arguments_equal_to "$FUN_NAME" "$FUN_ARG_NUM" "$#" || exit 1

  local VARIABLE_NAME="$1"
  local VARIABLE_VALUE="$2"

  check_not_empty_arguments "$FUN_NAME" "$VARIABLE_NAME" || exit 1

  if ! variable_is_initialized "$VARIABLE_NAME" ; then
    return 1
  fi

  local CUR_VALUE="\$$VARIABLE_NAME"
  CUR_VALUE=`eval printf "$CUR_VALUE"`

  if [ "$CUR_VALUE" != "$VARIABLE_VALUE" ] ; then
    return 1
  fi

  return 0
}


initialize_constant () {
  local FUN_NAME='initialize_constant'
  local FUN_ARG_NUM='2'

  check_num_arguments_equal_to "$FUN_NAME" "$FUN_ARG_NUM" "$#" || exit 1

  local VARIABLE_NAME="$1"
  local VARIABLE_VALUE="$2"

  check_not_empty_arguments "$FUN_NAME" "$VARIABLE_NAME" || exit 1

  if ! variable_is_initialized "$VARIABLE_NAME" ; then
    eval readonly "${VARIABLE_NAME}=${VARIABLE_VALUE}"
    return 0
  fi

  if ! variable_is_read_only "$VARIABLE_NAME" ; then
    eval readonly "${VARIABLE_NAME}=${VARIABLE_VALUE}"
    return 0
  fi

  if check_variable_value "$VARIABLE_NAME" "$VARIABLE_VALUE" ; then
    return 0
  fi

  return 1
}


initialize_multiple_constants () {
  local FUN_NAME='initialize_multiple_constants'
  local FUN_ARG_NUM='0'

  check_num_arguments_equal_to "$FUN_NAME" "$FUN_ARG_NUM" "$#" || exit 1

  local VARIABLE_NAME=''
  local VARIABLE_VALUE=''
  local DEFINITION=''
  local RESULT='0'

  while read DEFINITION ; do
    printf '%s\n' "$DEFINITION" | grep -qE '^[[:blank:]]*$' && continue

    VARIABLE_NAME="${DEFINITION%%=*}"
    VARIABLE_VALUE="${DEFINITION#*=}"

    initialize_constant "${VARIABLE_NAME}" "${VARIABLE_VALUE}"
    if [[ "$RESULT" -eq 0 && "$?" -ne 0 ]] ; then
      RESULT='1'
    fi
  done

  return $RESULT
}


initialize_multiple_constants << EOF

FAILURE=1
SUCCESS=0

EXIT_FAILURE=1
EXIT_SUCCESS=0

OPTLOCAL='/opt/local'
USRLOCAL='/usr/local'

EOF

PATH="$OPTLOCAL/bin:$OPTLOCAL/sbin:$PATH"


###
} # COMMON_SH
###

