Install kubernetes without docker in redhat 7.6
==

## Sumary

> This document follows the official kubernetes documentation

1. [Configure **yum** and run **yum update**](https://github.com/paliari-ti/dev-ops/blob/master/kubernetes/EXTRAS.md#configurar-yum)
2. Install the [requirements](https://github.com/paliari-ti/dev-ops/tree/master/kubernetes#requirements), [containerd](https://github.com/paliari-ti/dev-ops/tree/master/kubernetes#containerd), [kubeadm, kubelet and kubectl](https://github.com/paliari-ti/dev-ops/tree/master/kubernetes#kubeadm-kubelet-kubectl)
    
    For these items, you can run manually or simply run the [convenience script](https://github.com/paliari-ti/dev-ops/blob/master/kubernetes/install.sh) to install everything

    `curl -fsSL https://raw.githubusercontent.com/paliari-ti/dev-ops/master/kubernetes/install.sh | bash`

3. [Create the cluster](https://github.com/paliari-ti/dev-ops/tree/master/kubernetes#creating-the-cluster)


## Requirements

```bash
# disable swap
swapoff -a
sed -i 's/\/dev\/mapper\/rhel-swap/#\/dev\/mapper\/rhel-swap/g' /etc/fstab

# disable firewalld
systemctl disable firewalld
systemctl stop firewalld
```

## [Containerd](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd)

```bash
cat > /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack_ipv4
ip_vs
EOF

modprobe overlay
modprobe br_netfilter
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh
modprobe ip_vs
modprobe nf_conntrack_ipv4

# Setup required sysctl params, these persist across reboots.
cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

# Install containerd
## Set up the repository
### Install required packages
yum install -y yum-utils device-mapper-persistent-data lvm2 libseccomp

### Add docker repository
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

## Install containerd
yum update -y && yum install -y containerd.io

# Configure containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

# Restart and enale containerd
systemctl restart containerd
systemctl enable containerd
```

## [kubeadm, kubelet, kubectl](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl)

```bash
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl enable --now kubelet
```

## [Creating the cluster](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)


### Only on master

```bash
kubeadm config images pull
kubeadm init --cri-socket "unix:///run/containerd/containerd.sock"

# normal user
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# root user
export KUBECONFIG=/etc/kubernetes/admin.conf
echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> /root/.bashrc

# pod network
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```

### Only on workers

```bash
kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash> --cri-socket "unix:///run/containerd/containerd.sock"
```

### Tear down

[SEE](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#tear-down)