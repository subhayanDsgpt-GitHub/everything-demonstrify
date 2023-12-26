#!/bin/sh

set -e

# Enable iptables Bridged Traffic on all the nodes.
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system


# Disable Swap on all the nodes.
sudo swapoff -a
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true


# Install CRI-O Runtime on all The nodes.
OS="xUbuntu_22.04"

VERSION="1.28"

cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF
cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /
EOF

# Add the GPG keys for CRI-O to the system’s list of trusted keys.
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -

# Update and install crio and crio-tools.
sudo apt-get update
sudo apt-get install cri-o cri-o-runc cri-tools -y

# Reload the systemd configurations and enable cri-o.
sudo systemctl daemon-reload
sudo systemctl enable crio --now


# Install Kubeadm & Kubelet & Kubectl on all nodes.
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

# Download the GPG key for the Kubernetes APT repository.
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg

# Add the Kubernetes APT repository to your system.
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl

# Add hold to the packages to prevent upgrades.
sudo apt-mark hold kubelet kubeadm kubectl
