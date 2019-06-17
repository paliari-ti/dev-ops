# Construindo um cluster Kubernetes sem utilizar o Docker no RedHat

## Instalando Kubernetes com containerd e runc sem o Docker

```bash
curl -fsSL https://raw.githubusercontent.com/paliari-ti/dev-ops/master/kubernetes/install.sh | bash
```
After the installation finished, follow the steps below

## Only on MASTER

```bash
kubeadm init --apiserver-advertise-address $(hostname -I) --cri-socket /run/containerd/containerd.sock
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
kubectl get nodes
```

If you want to allow to run pods on master `kubectl taint nodes --all node-role.kubernetes.io/master-`

## Only on WORKERS

Replace the variables below with the correct values

```bash
kubeadm join $MASTER_IP:6443 --token $TOKEN --discovery-token-ca-cert-hash $DISCOVERY_TOKEN --cri-socket /run/containerd/containerd.sock
```

## Helpfull commands

```
systemctl status containerd
containerd --help
runc --help
runc list
ls /run/containerd/containerd.sock
```
