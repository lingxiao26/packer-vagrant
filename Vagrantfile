# -*- mode: ruby -*-
# vi: set ft=ruby :

box = "centos-7.9"
vms = [
  {
    "hostname" => "node1",
    "ip" => "192.168.66.201"
  }
]

Vagrant.configure("2") do |config|
  config.vm.box = box

  # ssh config
  config.ssh.insert_key = false
  config.ssh.username = 'ecs-user'
  config.ssh.private_key_path = '~/.ssh/tyrion'

  # config.vm.provision "shell", inline: <<-SHELL
  #   mkdir ~/provision
  # SHELL
  # config.vm.provision "file", source: "./provision/*", destination: "~/provision" # 3
  # config.vm.provision "file", source: "~/.vagrant.d/insecure_private_key", destination: "~/.ssh/" # 3

  # config.disksize.size = '50GB'
  config.vm.provider :virtualbox do |v|
    v.memory = 2048
    v.cpus = 2
    v.linked_clone = true
  end

  vms.each do |vm|
    config.vm.define vm['hostname'] do |node|
      node.vm.network :private_network, ip: vm['ip'], bridge: 'vboxnet0'
      node.vm.hostname = vm['hostname']
    end
  end
end

