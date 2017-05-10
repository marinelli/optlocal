#!/bin/sh

###
[ -z "$DNS_SH" ] && {
readonly DNS_SH='dns.sh'
###


. /opt/local/lib/common.sh


dns_temp_enable () {
  local FUN_NAME='dns_temp_enable'
  local FUN_ARG_NUM='0'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_equal_to "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  [ -f /etc/resolv.conf ] && {
    rm -f /etc/resolv.conf
    ln -s /tmp/resolv.conf.temp /etc/resolv.conf
  }

  cat > /etc/resolv.conf << EOF
nameserver 8.8.8.8
EOF

  [ -f /tmp/resolv.conf.auto ] && {
    cat /tmp/resolv.conf.auto >> /etc/resolv.conf
  }

  return $SUCCESS
}


dns_temp_disable () {
  local FUN_NAME='dns_temp_disable'
  local FUN_ARG_NUM='0'
  local STACK_TRACE="$STACK_TRACE $FUN_NAME"

  check_num_arguments_equal_to "$FUN_ARG_NUM" "$#" \
    || exit $EXIT_FAILURE

  [ -f /etc/resolv.conf ] && rm -f /etc/resolv.conf
  ln -s /tmp/resolv.conf /etc/resolv.conf

  return $SUCCESS
}


###
debug_message "$DNS_SH included"
} || true
###

