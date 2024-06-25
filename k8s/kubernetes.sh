#!/usr/bin/env bash

# set selinux permissive
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# set ipv4 packet forwarding
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
# apply without reboot
sudo sysctl --system

# add pkg.k8s.io repositorie:wq
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
EOF

# enable crio-o
cat <<EOF | sudo tee /etc/yum.repos.d/cri-o.repo
[cri-o]
name=CRI-O
baseurl=https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/rpm/repodata/repomd.xml.key
EOF

sudo yum update -y
sudo yum install -y kubectl kubeadm kubelet cri-o cri-tools kubernetes-cni containernetworking-plugins
sudo systemctl enable --now crio

mkdir -p /home/vagrant/.kube/
sudo chown vagrant:vagrant /home/vagrant/.kube/config

if [[ $(hostnamectl hostname) -eq "controlplane" ]] ; then
  # control-plane
  sudo kubeadm init
  sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
fi

