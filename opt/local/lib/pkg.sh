#!/bin/sh

###
[ -z "$PKG_SH" ] && {
readonly PKG_SH='pkg.sh'
###


. /opt/local/lib/common.sh


pkg_installed () {
  local FUN_NAME='pkg_installed'
  local FUN_ARG_NUM='1'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_equal_to "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local PACKAGE="$1"

  check_not_empty_arguments "$PACKAGE" \
    || exit $EXIT_FAILURE

  if [ -n "`opkg list-installed ${PACKAGE}`" ] ; then
    return $SUCCESS
  else
    return $FAILURE
  fi
}


pkg_filter_installed () {
  local FUN_NAME='pkg_filter_installed'
  local FUN_ARG_NUM='0'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_at_least "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local PKGS=''

  local CUR_PKG=''
  while [ "$#" -gt 0 ] ; do
    CUR_PKG="$1"
    shift 1

    check_not_empty_arguments "$CUR_PKG" \
      || exit $EXIT_FAILURE

    pkg_installed "$CUR_PKG" && PKGS="${PKGS:+${PKGS} }${CUR_PKG}"
  done
  unset CUR_PKG

  printf "$PKGS"

  return $SUCCESS
}


pkg_filter_not_installed () {
  local FUN_NAME='pkg_filter_not_installed'
  local FUN_ARG_NUM='0'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_at_least "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local PKGS=''

  local CUR_PKG=''
  while [ "$#" -gt 0 ] ; do
    CUR_PKG="$1"
    shift 1

    check_not_empty_arguments "$CUR_PKG" \
      || exit $EXIT_FAILURE

    ! pkg_installed "$CUR_PKG" && PKGS="${PKGS:+${PKGS} }${CUR_PKG}"
  done
  unset CUR_PKG

  printf "$PKGS"

  return $SUCCESS
}


pkg_install () {
  local FUN_NAME='pkg_install'
  local FUN_ARG_NUM='1'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_at_least "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local PKGS="$@"

  check_not_empty_arguments "$PKGS" \
    || exit $EXIT_FAILURE

  PKGS=`pkg_filter_not_installed $PKGS`

  if check_not_empty_arguments "$PKGS" 2>/dev/null ; then
    opkg install $PKGS
  else
    return $SUCCESS
  fi

  local RESULT="$?"

  PKGS=`pkg_filter_not_installed $PKGS`

  if [ -n "$PKGS" ] ; then
    info_message "these packages have not been installed $PKGS"
  fi

  return $RESULT
}


pkg_remove () {
  local FUN_NAME='pkg_remove'
  local FUN_ARG_NUM='1'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_at_least "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local PKGS="$@"

  check_not_empty_arguments "$PKGS" \
    || exit $EXIT_FAILURE

  PKGS=`pkg_filter_installed $PKGS`

  if check_not_empty_arguments "$PKGS" 2>/dev/null ; then
    opkg remove $PKGS
  else
    return $SUCCESS
  fi

  local RESULT="$?"

  PKGS=`pkg_filter_installed $PKGS`

  if [ -n "$PKGS" ] ; then
    info_message "these packages have not been removed $PKGS"
  fi

  return $RESULT
}


###
debug_message "$PKG_SH included"
} || true
###

