
. /opt/local/lib/optlocal.sh
. /opt/local/lib/pkg.sh

pkg_install dnsmasq

disable_and_stop_daemon dnsmasq

[ -d /etc/dnsmasq.conf.d ] && rm -fr /etc/dnsmasq.conf.d

find /opt/local/etc/dnsmasq.conf.d/ -type f \! -name \*.off | \
  optlocal link dest=/

optlocal copy etc/dnsmasq.conf dest=/
optlocal copy etc/init.d/dnsmasq dest=/

proctl enable dnsmasq
proctl start dnsmasq

