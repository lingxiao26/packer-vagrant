#!/bin/bash

set -e
set -x

if [ "$PACKER_BUILDER_TYPE" != "virtualbox-iso" ]; then
  exit 0
fi

yum -y install bzip2
yum -y --enablerepo=epel install dkms
yum -y install kernel-devel
yum -y install make
yum -y install perl

# Uncomment this if you want to install Guest Additions with support for X
#yum -y install xorg-x11-server-Xorg

# In CentOS 6 or earlier, dkms package provides SysV init script called
# dkms_autoinstaller that is enabled by default
if systemctl list-unit-files | grep -q dkms.service; then
  systemctl start dkms
  systemctl enable dkms
fi

mount -o loop,ro ~/VBoxGuestAdditions.iso /mnt/
/mnt/VBoxLinuxAdditions.run || :
umount /mnt/
rm -f ~/VBoxGuestAdditions.iso
