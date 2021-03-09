#!/bin/bash

disable_firewall() {
  systemctl stop firewalld
  systemctl disable firewalld
}

disable_swap() {
  sed -i '/swap/d' /etc/fstab
  swapoff -a
}

edit_hosts() {
  cat <<EOF >/etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.66.201 node1
192.168.66.202 node2
192.168.66.203 node3
EOF
}

bash_completion() {
  echo 'source <(kubectl completion bash)' >>~/.bashrc
  echo 'alias k=kubectl' >>~/.bashrc
  echo 'complete -F __start_kubectl k' >>~/.bashrc
}

modify_kernel_args() {
  cat <<EOF >/etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

  # reload kernel
  sysctl -p

  # load bridge filter module
  modprobe br_netfilter

  # check bridge filter module is load successful
  lsmod | grep br_netfilter
}

config_ipvs() {
  # install ipset and ipvsadm
  yum install ipset ipvsadm -y

  # add module required
  cat <<EOF >/etc/sysconfig/modules/ipvs.modules
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF

  # add execute mode
  chmod +x /etc/sysconfig/modules/ipvs.modules

  # execute script
  bash /etc/sysconfig/modules/ipvs.modules

  # check module is load successful
  lsmod | grep -e ip_vs -e nf_conntrack_ipv4
}

install_k8s_components() {
  cat <<EOF >/etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

  setenforce 0
  yum install -y --nogpgcheck kubelet kubeadm kubectl
  systemctl enable kubelet
}

pull_k8s_depend_images() {
  cat <<'EOF' >./k8s-dependency-image-pull.sh
#!/bin/bash

images=($(kubeadm config images list))

aliyun="registry.cn-hangzhou.aliyuncs.com/google_containers"

for image in ${images[@]}; do
  image_name=$(echo $image | awk -F'/' '{print $2}')
  docker pull $aliyun/$image_name
  docker tag $aliyun/$image_name $image
  docker rmi $aliyun/$image_name
done
EOF

  bash ./k8s-dependency-image-pull.sh
  docker images
}

init_k8s() {
  kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.66.201
}

master_install() {
  disable_firewall
  disable_swap
  edit_hosts
  modify_kernel_args
  config_ipvs
  bash_completion
  install_k8s_components
  pull_k8s_depend_images
  init_k8s
}

node_install() {
  disable_firewall
  disable_swap
  edit_hosts
  modify_kernel_args
  config_ipvs
  install_k8s_components
  pull_k8s_depend_images
}

#master_install
node_install
