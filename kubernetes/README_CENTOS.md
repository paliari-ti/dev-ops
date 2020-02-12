Install kubernetes with docker in CentOs
==

## Sumary

> This document follows the official kubernetes documentation

1. [Configure **yum** and run **yum update**](https://github.com/paliari-ti/dev-ops/blob/master/kubernetes/EXTRAS.md#configurar-yum)
2. Install the [requirements](https://github.com/paliari-ti/dev-ops/tree/master/kubernetes#requirements), [containerd](https://github.com/paliari-ti/dev-ops/tree/master/kubernetes#containerd), [kubeadm, kubelet and kubectl](https://github.com/paliari-ti/dev-ops/tree/master/kubernetes#kubeadm-kubelet-kubectl)
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

## [Docker](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker)

```bash
# Install Docker CE
## Set up the repository
### Install required packages.
yum install -y yum-utils device-mapper-persistent-data lvm2

### Add Docker repository.
yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

## Install Docker CE.
yum update -y && yum install -y \
  containerd.io-1.2.10 \
  docker-ce-19.03.4 \
  docker-ce-cli-19.03.4

## Create /etc/docker directory.
mkdir /etc/docker

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart Docker
systemctl enable docker
systemctl daemon-reload
systemctl restart docker
```

## [kubeadm, kubelet, kubectl](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl)

```bash
modprobe br_netfilter

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
kubeadm init --apiserver-advertise-address=192.168.1.100 --apiserver-cert-extra-sans=your.domain.com

kubeadm join 192.168.1.100:6443 --token <token> --discovery-token-ca-cert-hash <cert-hash>


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
kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash>
```

### Tear down

[SEE](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#tear-down)