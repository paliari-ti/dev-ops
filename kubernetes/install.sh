#!/bin/bash
set -e

## Construindo um cluster Kubernetes sem utilizar o Docker no RedHat

## Etapas em ambos, master e workers
yum update -y
yum install -y wget

## Open ports
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10252/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --reload

## Configs
cat > /etc/modules-load.d/k8s.conf <<EOF
br_netfilter
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack_ipv4
ip_vs
EOF

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward=1
EOF

sysctl --system
modprobe br_netfilter
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh
modprobe ip_vs
modprobe nf_conntrack_ipv4

## Kubernetes
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

## Containerd e runc
wget https://github.com/containerd/containerd/releases/download/v1.1.2/containerd-1.1.2.linux-amd64.tar.gz

tar -xvzf containerd-1.1.2.linux-amd64.tar.gz

mv bin/* /usr/local/bin/

rm -rf bin containerd-1.1.2.linux-amd64.tar.gz

ls -lha /usr/local/bin/containerd

wget -O /usr/local/sbin/runc https://github.com/opencontainers/runc/releases/download/v1.0.0-rc5/runc.amd64

ls -lha /usr/local/sbin/runc

chmod +x /usr/local/sbin/runc

ls -lha /usr/local/sbin/runc

containerd --version

runc --version

curl -o /etc/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/cri/master/contrib/systemd-units/containerd.service

systemctl daemon-reload

systemctl enable containerd

systemctl start containerd

systemctl status containerd

echo "runtime-endpoint: unix:///run/containerd/containerd.sock" > /etc/crictl.yaml

systemctl daemon-reload

systemctl enable kubelet

echo "Installation finished"