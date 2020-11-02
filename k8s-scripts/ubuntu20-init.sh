#!/bin/sh

set -x

apt-get update
apt-get upgrade
apt-get install curl

# Check VXLAN exists
curl -sSL https://raw.githubusercontent.com/docker/docker/master/contrib/check-config.sh | bash

#### Docker


# Install Docker CE
## Set up the repository:
### Install packages to allow apt to use a repository over HTTPS
apt-get update && apt-get install -y \
  apt-transport-https ca-certificates curl software-properties-common gnupg2

### Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

### Add Docker apt repository.
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

## Install Docker CE.
apt-get update && apt-get install -y \
  containerd.io \
  docker-ce \
  docker-ce-cli

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker


#### End Docker

apt-get install -y bash-completion
source /usr/share/bash-completion/bash_completion

apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update
apt-get install -y kubelet kubeadm kubectl

echo "source <(kubeadm completion bash);source <(kubectl completion bash);alias nano='nano -cmET4';echo 'Hello k8s'" >> ~/.bashrc
sudo kubeadm init --pod-network-cidr=10.240.0.0/16 | tee /root/kubeadm-init-output.txt

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

curl https://docs.projectcalico.org/manifests/calico.yaml -O

kubectl apply -f calico.yaml