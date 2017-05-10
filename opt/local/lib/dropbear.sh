#!/bin/sh

###
[ -z "$DROPBEAR_SH" ] && {
readonly DROPBEAR_SH='dropbear.sh'
###


. /opt/local/lib/common.sh


dropbear_find_keys () {
  local FUN_NAME='dropbear_find_keys'
  local FUN_ARG_NUM='1'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  local DROPBEAR_ETC="$1"
  local PATTERN="$2"

  if [[ -z "$DROPBEAR_ETC" || ! -d "$DROPBEAR_ETC" ]] ; then
    return $FAILURE
  fi

  if [ -z "$PATTERN" ] ; then
    PATTERN='dropbear_*_host_key'
  fi

  find "$DROPBEAR_ETC" \
      -mindepth 1 -maxdepth 1 -type f \
      -name "$PATTERN" \
    || return $FAILURE

  return $SUCCESS
}


dropbear_copy_keys () {
  local FUN_NAME='dropbear_copy_keys'
  local FUN_ARG_NUM='2'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  local DROPBEAR_SRC_ETC="$1"
  local DROPBEAR_DST_ETC="$2"
  local PATTERN="$3"

  if [[ -z "$DROPBEAR_SRC_ETC" || ! -d "$DROPBEAR_SRC_ETC" \
     || -z "$DROPBEAR_DST_ETC" || ! -d "$DROPBEAR_DST_ETC" ]] ; then
    return $FAILURE
  fi

  if [ -z "$PATTERN" ] ; then
    PATTERN='dropbear_*_host_key'
  fi

  find "$DROPBEAR_SRC_ETC" \
      -mindepth 1 -maxdepth 1 -type f \
      -name "$PATTERN" \
      -exec cp -a '{}' "$DROPBEAR_DST_ETC" \; \
    || return $FAILURE

  return $SUCCESS
}


dropbear_keytypes () {
  local FUN_NAME='dropbear_keystypes'
  local FUN_ARG_NUM='1'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  local DROPBEAR_PATH="$1"

  if [[ -z "$DROPBEAR_PATH" || ! -x "$DROPBEAR_PATH" ]] ; then
    return $FAILURE
  fi

  "$DROPBEAR_PATH" -h 2>&1 | \
    sed -rn 's/^[[:blank:]]+([[:alnum:]]+)[[:blank:]]+.+dropbear_\1_host_key/\1/p'

  return $SUCCESS
}


dropbear_bootstrap () {
  local FUN_NAME='dropbear_bootstrap'
  local FUN_ARG_NUM='0'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  local DROPPORT='22222'
  local DROPBOOT=`mktemp -d /tmp/dropbear-bootstrap.XXXXXX 2>/dev/null`

  find /tmp -mindepth 1 -maxdepth 1 -type d \
      -depth -name dropbear-bootstrap.?????? \
  | while read CUR_PATH ; do
      if [ -f "${CUR_PATH}/dropbear.pid" ] ; then
        CUR_PID=`cat "${CUR_PATH}/dropbear.pid"`
      fi
      if [ -n "$CUR_PID" ] ; then
        pidof dropbear | grep -q "$CUR_PID" && kill -9 "$CUR_PID"
      fi
      if [[ -x "${CUR_PATH}/dropbear" && ! -x "${DROPBOOT}/dropbear" ]] ; then
        mv "${CUR_PATH}/dropbear" "$DROPBOOT"
      fi
      if [ "$CUR_PATH" != "$DROPBOOT" ] ; then
        rm -fr "$CUR_PATH"
      fi
    done

  if [ ! -d "$DROPBOOT" ] ; then
    return $FAILURE
  fi

  local DROPBEAR=''

  if [ -x "${DROPBOOT}/dropbear" ] ; then
    DROPBEAR="${DROPBOOT}/dropbear"
  else
    DROPBEAR=`which dropbear 2>/dev/null || return $FAILURE`
    cp -a "$DROPBEAR" "$DROPBOOT" \
      || return $FAILURE
  fi

  dropbear_copy_keys "${OPTLOCAL}/etc/dropbear" "$DROPBOOT" \
    || return $FAILURE

  local DROPKEYS=`dropbear_find_keys "$DROPBOOT" || return $FAILURE`

  if [[ -z "$DROPKEYS" ]] ; then
    ln -s "${DROPBOOT}/${DROPBEAR##*/}" "${DROPBOOT}/dropbearkey" \
      || return $FAILURE

    for CUR_TYPE in `dropbear_keytypes` ; do
      "${DROPBOOT}/dropbearkey" \
          -t "$CUR_TYPE" \
          -f "${DROPBOOT}/dropbear_${CUR_TYPE}_host_key" \
          >/dev/null 2>&1 \
        || return $FAILURE
    done
    unset CUR_TYPE
  fi

  for CUR_KEY in `dropbear_find_keys /etc/dropbear` ; do
    mv "$CUR_KEY" "${CUR_KEY}.off" || return $FAILURE
  done
  unset CUR_KEY

  for IPTABLES_CMD in `which iptables` `which ip6tables` ; do
    "$IPTABLES_CMD" \
        -t filter -A input_wan_rule -p tcp -m tcp --dport $DROPPORT -j ACCEPT \
        -m comment --comment Allow-Bootstrap-SSH \
      || return $FAILURE
  done
  unset IPTABLES_CMD

  local DROPBEAR_ARGS="-p $DROPPORT -P ${DROPBOOT}/dropbear.pid"

  for CUR_KEY in `dropbear_find_keys "$DROPBOOT"` ; do
    DROPBEAR_ARGS="${DROPBEAR_ARGS:+${DROPBEAR_ARGS} }-r ${CUR_KEY}"
  done
  unset CUR_KEY

  eval "${DROPBOOT}/${DROPBEAR##*/}" $DROPBEAR_ARGS \
    || return $FAILURE

  for CUR_KEY in `dropbear_find_keys /etc/dropbear 'dropbear_*_host_key.off'` ; do
    mv "$CUR_KEY" "${CUR_KEY%%.off}"
  done
  unset CUR_KEY

  return $SUCCESS
}


###
debug_message "$DROPBEAR_SH included"
} || true
###

