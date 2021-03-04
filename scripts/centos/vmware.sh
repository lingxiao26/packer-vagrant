#!/bin/bash

set -e
set -x

if [ "$PACKER_BUILDER_TYPE" != "vmware-iso" ]; then
  exit 0
fi

yum -y install perl
yum -y install net-tools
yum -y install make
yum -y install gcc
yum -y install kernel-devel

mkdir /mnt/vmware
mount -o loop,ro ~/linux.iso /mnt/vmware

mkdir /tmp/vmware
tar zxf /mnt/vmware/VMwareTools-*.tar.gz -C /tmp/vmware

/tmp/vmware/vmware-tools-distrib/vmware-install.pl --default --force-install
rm -r /tmp/vmware

umount /mnt/vmware
rm -r /mnt/vmware
rm -f ~/linux.iso

tee -a /etc/vmware-tools/locations <<EOF
remove_answer ENABLE_VGAUTH
answer ENABLE_VGAUTH no
remove_answer ENABLE_VMBLOCK
answer ENABLE_VMBLOCK no
EOF
/usr/bin/vmware-config-tools.pl --default --skip-stop-start
