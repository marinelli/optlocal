#!/bin/sh

###
[ -z "$PKG_SH" ] && {
readonly PKG_SH='included'
###


. /opt/local/lib/common.sh


pkg_installed () {
  local FUN_NAME='pkg_installed'
  local FUN_ARG_NUM='1'

  check_num_arguments_equal_to "$FUN_NAME" "$FUN_ARG_NUM" "$#" || \
    exit $EXIT_FAILURE

  local PACKAGE="$1"

  check_not_empty_arguments "$FUN_NAME" "$PACKAGE" || \
    exit $EXIT_FAILURE

  if [ -n "`opkg list-installed ${PACKAGE}`" ] ; then
    return $SUCCESS
  else
    return $FAILURE
  fi
}


pkg_filter_installed () {
  local FUN_NAME='pkg_filter_installed'
  local FUN_ARG_NUM='0'

  check_num_arguments_at_least "$FUN_NAME" "$FUN_ARG_NUM" "$#" || \
    exit $EXIT_FAILURE

  local PKGS=''

  local CUR_PKG=''
  while [ "$#" -gt 0 ] ; do
    CUR_PKG="$1"
    shift 1

    check_not_empty_arguments "$FUN_NAME" "$CUR_PKG" || \
      exit $EXIT_FAILURE

    pkg_installed "$CUR_PKG" && PKGS="${CUR_PKG}${PKGS:+ ${PKGS}}"
  done
  unset CUR_PKG

  printf "$PKGS"

  return $SUCCESS
}


pkg_filter_not_installed () {
  local FUN_NAME='pkg_filter_not_installed'
  local FUN_ARG_NUM='0'

  check_num_arguments_at_least "$FUN_NAME" "$FUN_ARG_NUM" "$#" || \
    exit $EXIT_FAILURE

  local PKGS=''

  local CUR_PKG=''
  while [ "$#" -gt 0 ] ; do
    CUR_PKG="$1"
    shift 1

    check_not_empty_arguments "$FUN_NAME" "$CUR_PKG" || \
      exit $EXIT_FAILURE

    ! pkg_installed "$CUR_PKG" && PKGS="${CUR_PKG}${PKGS:+ ${PKGS}}"
  done
  unset CUR_PKG

  printf "$PKGS"

  return $SUCCESS
}


pkg_install () {
  local FUN_NAME='pkg_install'
  local FUN_ARG_NUM='1'

  check_num_arguments_at_least "$FUN_NAME" "$FUN_ARG_NUM" "$#" || \
    exit $EXIT_FAILURE

  local PKGS="$@"

  check_not_empty_arguments "$FUN_NAME" "$PKGS" || \
    exit $EXIT_FAILURE

  PKGS=`pkg_filter_not_installed $PKGS`

  check_not_empty_arguments "$FUN_NAME" "$PKGS" 2>/dev/null && \
    opkg install $PKGS

  local RESULT="$?"

  PKGS=`pkg_filter_not_installed $PKGS`

  if [ -n "$PKGS" ] ; then
    printf "!! %s : %s\n" "$FUN_NAME" \
      "these packages haven't been installed $PKGS" 1>&2
  fi

  return $RESULT
}


pkg_remove () {
  local FUN_NAME='pkg_remove'
  local FUN_ARG_NUM='1'

  check_num_arguments_at_least "$FUN_NAME" "$FUN_ARG_NUM" "$#" || \
    exit $EXIT_FAILURE

  local PKGS="$@"

  check_not_empty_arguments "$FUN_NAME" "$PKGS" || \
    exit $EXIT_FAILURE

  PKGS=`pkg_filter_installed $PKGS`

  check_not_empty_arguments "$FUN_NAME" "$PKGS" 2>/dev/null && \
    opkg remove $PKGS

  local RESULT="$?"

  PKGS=`pkg_filter_installed $PKGS`

  if [ -n "$PKGS" ] ; then
    printf "!! %s : %s\n" "$FUN_NAME" \
      "these packages haven't been removed $PKGS" 1>&2
  fi

  return $RESULT
}


###
} # PKG_SH
###

