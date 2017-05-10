#!/bin/sh

###
[ -z "$BOOTSTRAP_SH" ] && {
readonly BOOTSTRAP_SH='bootstrap.sh'
###


. /opt/local/lib/common.sh


build_bootstrap_fun () {
  local FUN_NAME='build_bootstrap_fun'
  local FUN_ARG_NUM='1'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_equal_to "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local BOOTSTRAP_FUN_FILE="${1##*/}"
  local BOOTSTRAP_FUN_NAME="bootstrap_${BOOTSTRAP_FUN_FILE%.sh}"

  check_not_empty_arguments "$BOOTSTRAP_FUN_FILE" \
    || exit $EXIT_FAILURE

  [ ! -f "${OPTLOCAL}/lib/bootstraps/${BOOTSTRAP_FUN_FILE}" ] \
    && return $FAILURE

  local BOOTSTRAP_TMP="${TMP_PATH}/bootstraps"

  [ -f "$BOOTSTRAP_TMP" ] && rm "$BOOTSTRAP_TMP"
  [ ! -d "$BOOTSTRAP_TMP" ] && mkdir "$BOOTSTRAP_TMP"

  local BOOTSTRAP_PATH=`mktemp -d "${BOOTSTRAP_TMP}/${BOOTSTRAP_FUN_NAME}.XXXXXX"`

  if [[ -z "$BOOTSTRAP_PATH" || ! -d "$BOOTSTRAP_PATH" ]] ; then
    exit $EXIT_FAILURE
  fi

  local BOOTSTRAP_FILE_PATH="${BOOTSTRAP_PATH}/${BOOTSTRAP_FUN_NAME}"

  [ -f "$BOOTSTRAP_FILE_PATH" ] && rm "$BOOTSTRAP_FILE_PATH"

  printf '%s\n' "${BOOTSTRAP_FUN_NAME} () {" \
      >> "$BOOTSTRAP_FILE_PATH"

  printf '%s\n' "info_message \"starting ${BOOTSTRAP_FUN_FILE%.sh} setup\"" \
      >> "$BOOTSTRAP_FILE_PATH"

  cat "${OPTLOCAL}/lib/bootstraps/${BOOTSTRAP_FUN_FILE}" \
      >> "$BOOTSTRAP_FILE_PATH"

  printf '%s\n' '}' \
      >> "$BOOTSTRAP_FILE_PATH"

  printf '%s\n' "debug_message \"${BOOTSTRAP_FUN_NAME} loaded\"" \
      >> "$BOOTSTRAP_FILE_PATH"

  unset "$BOOTSTRAP_FUN_NAME"

  . "$BOOTSTRAP_FILE_PATH"

  if [ -d "$BOOTSTRAP_PATH" ] ; then
    rm -fr "$BOOTSTRAP_PATH"
  fi

  return $SUCCESS
}


load_bootstrap_funs () {
  local FUN_NAME='load_bootstrap_funs'
  local FUN_ARG_NUM='0'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_equal_to "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local FUNS_TO_LOAD=`find "${OPTLOCAL}/lib/bootstraps/" -mindepth 1 -maxdepth 1 -type f \! -name \*.off`

  if [ -z "$FUNS_TO_LOAD" ] ; then
    return $SUCCESS
  fi

  local BOOTSTRAP_FUNCTION=''
  for BOOTSTRAP_FUNCTION in $FUNS_TO_LOAD ; do
    build_bootstrap_fun "$BOOTSTRAP_FUNCTION"
  done
  unset BOOTSTRAP_FUNCTION

  return $SUCCESS
}


include_bootstrap_libs () {
  local FUN_NAME='include'
  local FUN_ARG_NUM='0'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_equal_to "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local LIBS_TO_LOAD=`find "${OPTLOCAL}/lib/" -mindepth 1 -maxdepth 1 -type f \! -name \*.off`

  if [ -z "$LIBS_TO_LOAD" ] ; then
    return $SUCCESS
  fi

  local BOOTSTRAP_LIBRARY=''
  for BOOTSTRAP_LIBRARY in $LIBS_TO_LOAD ; do
    if [ "${BOOTSTRAP_LIBRARY##*/}" != "$BOOTSTRAP_SH" ] ; then
      . "$BOOTSTRAP_LIBRARY" \
        || {
          error_message "${BOOTSTRAP_LIBRARY##*/} has not been loaded correctly"
          return $FAILURE
        }
    fi
  done
  unset BOOTSTRAP_LIBRARY

  return $SUCCESS
}


bootstrap () {
  local FUN_NAME='bootstrap'
  local FUN_ARG_NUM='0'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_at_least "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  local CONFIG_NAME="$1"

  if [[ -z "$CONFIG_NAME" && -f "$OPTLOCAL_CONFIG_PATH" ]] ; then
    . "$OPTLOCAL_CONFIG_PATH"
    if [ ! -z "$OPTLOCAL_CONFIG_NAME" ] ; then
      CONFIG_NAME="$OPTLOCAL_CONFIG_NAME"
    else
      error_message "OPTLOCAL_CONFIG_NAME is not defined in $OPTLOCAL_CONFIG_PATH"
      exit $EXIT_FAILURE
    fi
  fi

  ###

  info_message 'starting'

# wait_for_seconds 20

  optlocal link conf="$CONFIG_NAME" << EOF
bin/proctl bin/reboot bin/logout bin/diff-configs
bin/list-upgradable-pkgs bin/list-diff-configs
EOF

  optlocal copy conf="$CONFIG_NAME" dest=/ << EOF
etc/passwd etc/shadow etc/group
etc/hosts etc/profile etc/rc.local
etc/sysupgrade.conf
EOF

# find /opt/local/etc/config/ -type f \! -name \*.off | \
#   optlocal copy dest=/ conf="$CONFIG_NAME"

  optlocal copy dest=/ conf="$CONFIG_NAME" "etc/config/"

return 0

  disable_and_stop_daemon dnsmasq
  disable_and_stop_daemon dropbear

  dropbear_bootstrap

  pkg_remove dropbear

  proctl reload system
  proctl reload network

  wait_for_seconds 20

  dns_temp_enable

  pidof ntpd >/dev/null && proctl stop sysntpd
  /usr/sbin/ntpd -nqN \
      -p 0.europe.pool.ntp.org -p 1.europe.pool.ntp.org \
      -p 2.europe.pool.ntp.org -p 3.europe.pool.ntp.org \
      >/dev/null 2>&1
  proctl start sysntpd

  while true ; do
    opkg update >/dev/null 2>&1 && break
    sleep 5
  done


  load_bootstrap_funs

  bootstrap_openssh
  bootstrap_dnsmasq
  bootstrap_unbound
  bootstrap_miniupnpd


  pkg_install \
    6in4 ip ss bind-host bind-dig \
    diffutils patch vim zile terminfo

  pkg_remove \
    ppp ppp-mod-pppoe kmod-pppoe kmod-pppox\
    kmod-ppp kmod-slhc kmod-lib-crc-ccitt


  dns_temp_disable

  proctl reload network

  ! pidof dropbear >/dev/null && ! pidof ssh >/dev/null && {
    passwd -d root
  }

  info_message 'done'
}


###
debug_message "$BOOTSTRAP_SH included"
} || true
###

