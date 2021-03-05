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
  usermod -aG docker ecs-user
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
  git clone https://gitee.com/mirror-github/zsh-autosuggestions.git ~/.zsh/zsh-autosuggestions
  git clone https://gitee.com/mirror-github/zsh-autosuggestions.git /home/ecs-user/.zsh/zsh-autosuggestions
  tee -a ~/.zshrc <<EOF
  source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
EOF
  tee -a /home/ecs-user/.zshrc <<EOF
  source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
EOF

  # completion
  git clone https://gitee.com/herun/zsh-completions.git ~/.zsh/zsh-completions
  git clone https://gitee.com/herun/zsh-completions.git /home/ecs-user/.zsh/zsh-completions
  tee -a ~/.zshrc <<EOF
  fpath=(~/.zsh/zsh-completions/src $fpath)
EOF
  tee -a /home/ecs-user/.zshrc <<EOF
  fpath=(~/.zsh/zsh-completions/src $fpath)
EOF
  rm -f ~/.zcompdump
  # compinit
}

main() {
  install_docker
  # install_zsh
}

main
