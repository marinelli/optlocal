
. /opt/local/lib/optlocal.sh
. /opt/local/lib/pkg.sh

pkg_install openssh-server openssh-moduli openssh-client

disable_and_stop_daemon sshd

find /opt/local/etc/ssh/ -type f \! -name \*.off | \
  optlocal copy dest=/

proctl enable sshd
proctl start sshd

