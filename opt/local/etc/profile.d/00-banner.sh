#!/bin/sh

[ -f /etc/banner ] && cat /etc/banner

[ -e /tmp/.failsafe ] && cat /etc/banner.failsafe

