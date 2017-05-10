
. /opt/local/lib/optlocal.sh
. /opt/local/lib/pkg.sh

pkg_install unbound unbound-anchor

disable_and_stop_daemon unbound

find /opt/local/etc/unbound/ -type f \! -name \*.off | \
  optlocal copy dest=/

optlocal copy etc/init.d/unbound dest=/

proctl enable unbound
proctl start unbound

