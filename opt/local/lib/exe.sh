#!/bin/sh

###
[ -z "$EXE_SH" ] && {
readonly EXE_SH='included'
###


. /opt/local/lib/common.sh


export_required_commands () {
  local FUN_NAME='export_required_commands'
  local FUN_ARG_NUM='1'

  check_num_arguments_equal_to "$FUN_NAME" "$FUN_ARG_NUM" "$#" || \
    exit $EXIT_FAILURE

  local COMMANDS="$1"

  for CUR_CMD in $COMMANDS ; do
    CUR_CMD_PATH=$( which "$CUR_CMD" )

    if [ "$?" -ne "0" ] ; then
        printf '!!! %s\n' "\"${CUR_CMD}\" command not found" 1>&2
        return $FAILURE
    fi

    eval "__ext_${CUR_CMD##*/}=\"\${CUR_CMD_PATH}\""
  done

  return $SUCCESS
}


export_optional_commands () {
  local FUN_NAME='export_optional_commands'
  local FUN_ARG_NUM='1'

  check_num_arguments_equal_to "$FUN_NAME" "$FUN_ARG_NUM" "$#" || \
    exit $EXIT_FAILURE

  local COMMANDS="$1"

  for CUR_CMD in $COMMANDS ; do
    CUR_CMD_PATH=$( which "$CUR_CMD" )

    if [ "$?" -ne "0" ] ; then
      continue
    fi

    eval "__ext_${CUR_CMD##*/}=\"\${CUR_CMD_PATH}\""
  done

  return $SUCCESS
}


###
} # EXE_SH
###

