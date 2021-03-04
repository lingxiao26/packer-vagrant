#!/bin/bash

set -e
set -x

if rpm -q --whatprovides kernel | grep -Fqv "$(uname -r)"; then
  rpm -q --whatprovides kernel | grep -Fv "$(uname -r)" | xargs yum -y autoremove
fi

yum --enablerepo=epel clean all
yum history new
truncate -c -s 0 /var/log/yum.log
