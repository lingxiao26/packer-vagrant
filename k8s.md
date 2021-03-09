# kubernetes install

1. sync time

2. disable firewalld

3. disable selinux

4. disable swap

5. modify kernel args

```shell
cat << EOF > /etc/sysctl.d/kubernetes.conf
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
```

6. config ipvs

```shell
# install ipset and ipvsadm
yum install ipset ipvsadm -y

# add module required
cat << EOF > /etc/sysconfig/modules/ipvs.modules
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
```

6. reboot machine


7. install docker

8. install k8s required components
```shell
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
setenforce 0
yum install -y kubelet kubeadm kubectl
systemctl enable kubelet && systemctl start kubelet

# ps: 由于官网未开放同步方式, 可能会有索引gpg检查失败的情况, 这时请用 yum install -y --nogpgcheck kubelet kubeadm kubectl 安装
```


9.  prepare images that k8s required

```shell
cat << EOF > ./k8s-dependency-image-pull.sh
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

bash -x ./k8s-dependency-image-pull.sh
```

9. init kubernetes cluster
```shell
kubeadm init --apiserver-advertise-address=192.168.66.201
```

10. add node to cluster

11. install network plugin (flannel)