#!/bin/bash

set -e
set -x

USER=ecs-user

repo() {
  yum install wget -y

  wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
  wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
  sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo
  yum clean all
  yum makecache
}

virtualbox() {

  if [ "$PACKER_BUILDER_TYPE" != "virtualbox-iso" ]; then
    exit 0
  fi

  yum -y install bzip2
  yum -y --enablerepo=epel install dkms
  yum -y update kernel
  yum -y install kernel-headers
  yum -y install kernel-devel
  yum -y install make gcc
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
  # rm -f ~/VBoxGuestAdditions.iso
}

ssh_config() {
  date | tee /etc/vagrant_box_build_time

  mkdir -p ~/.ssh

  cat <<EOF >>~/.ssh/authorized_keys
  ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAswzlAEyWQzBaE7WESi9E9OJeTBKCh5ysRWTHNVWw/CpjxnN2KDm5Q6DKIeWYeMRUUmWC+aHFECs23OxVf0HISkCM623jsGoBUCN0Sh9rZyyN0leKiTEXGxaFf6oriQZ9v4CHuGZkm4dZmNzgfB06E/EA8e+tSZh0QB2XfKJxFxSf27BCn/uyuy5Bidk6HFWqTdNAY8+j9BJeo48j1RlBmBIAVtERTpLQ8CAKbGXM/1DFtftn+rm7RFULDdbhzOUd/Z4SibEPLKmvLdp3bMlNVK/F401X1+5gR1A5zYTlAmu9y9hGs0fHM8rglv458HlnPlQq2EPaBvXklvrR6yhVUQ== li.lingxiao
EOF

  chmod 700 ~/.ssh/
  chmod 600 ~/.ssh/authorized_keys

  tee -a /etc/ssh/sshd_config <<EOF

UseDNS no
EOF
}

install_common_tools() {
  yum install net-tools -y
  yum install curl -y
  yum install ansible -y
  yum install git -y
  yum install vim -y
  yum install bash-completion -y
}

install_docker() {
  # uninstall old docker
  yum remove -y docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-selinux \
    docker-engine-selinux \
    docker-engine

  # 2. install dependencies
  yum install -y yum-utils \
    device-mapper-persistent-data \
    lvm2

  # 3. add yum repo
  yum-config-manager \
    --add-repo \
    http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

  # 4. install docker-ce
  yum makecache fast
  yum install docker-ce -y

  # 4. install by script
  # curl -fsSL get.docker.com -o get-docker.sh
  # sh get-docker.sh --mirror Aliyun

  # 5. start docker
  systemctl enable docker
  # systemctl start docker

  # 6. setting registry-mirrors
  [ ! -d "/etc/docker" ] && mkdir /etc/docker
  cat <<EOF >>/etc/docker/daemon.json
  {
    "registry-mirrors": [
      "https://dockerhub.azk8s.cn",
      "https://reg-mirror.qiniu.com",
      "https://szw6m4sd.mirror.aliyuncs.com"
    ],
    "storage-driver": "overlay2",
    "storage-opts": [
      "overlay2.override_kernel_check=true"
    ],
    "exec-opts": ["native.cgroupdriver=systemd"]
  }
EOF

  # 7. restart docker
  # systemctl daemon-reload
  # systemctl restart docker

  # 8. test if docker install correct
  # docker info

  # 9. add user for Group docker
  usermod -aG docker $USER
}

install_zsh() {
  yum install -y zsh
  chsh -s /bin/zsh root
  chsh -s /bin/zsh ecs-user
  git clone https://gitee.com/mirrors/oh-my-zsh.git ~/.oh-my-zsh
  cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
  sudo -i -u ecs-user bash <<EOF
  git clone https://gitee.com/mirrors/oh-my-zsh.git ~/.oh-my-zsh
  cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
EOF

  # install zsh plugin
  # autosuggestions
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-autosuggestions /home/ecs-user/.zsh/zsh-autosuggestions
  tee -a ~/.zshrc <<EOF
  source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
EOF
  tee -a /home/ecs-user/.zshrc <<EOF
  source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
EOF

  # completion
  git clone git://github.com/zsh-users/zsh-completions.git ~/.zsh/zsh-completions
  git clone git://github.com/zsh-users/zsh-completions.git /home/ecs-user/.zsh/zsh-completions
  tee -a ~/.zshrc <<EOF
  fpath=(~/.zsh/zsh-completions/src $fpath)
EOF
  tee -a /home/ecs-user/.zshrc <<EOF
  fpath=(~/.zsh/zsh-completions/src $fpath)
EOF
  rm -f ~/.zcompdump
  compinit
}

clean() {
  # Zero out the rest of the free space using dd, then delete the written file.
  dd if=/dev/zero of=/EMPTY bs=1M
  rm -f /EMPTY

  # Add `sync` so Packer doesn't quit too early, before the large file is deleted.
  sync
}

main() {
  repo
  virtualbox
  ssh_config
  install_common_tools
  # install_docker
  # install_zsh
}

main
