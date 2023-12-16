#!/bin/bash
#####
# Set's root password and starts sshd
####
# @since: 2023-12-16
# @author: stev leibelt <artodeto@bazzline.net>
####

function _main ()
{
  echo ":: Setting root password"
  passwd
  echo ":: Adapting sshd and starting it"
  echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
  systemctl enable --now sshd

  echo ":: Use root@<ip_listed_below> from a remote machine to log in"
  ip a | grep inet
}

_main "${@}"
