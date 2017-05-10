
. /opt/local/lib/optlocal.sh
. /opt/local/lib/pkg.sh

pkg_install miniupnpd

disable_and_stop_daemon miniupnpd

optlocal copy etc/init.d/miniupnpd dest=/

proctl enable miniupnpd
proctl start miniupnpd

