# Construindo um cluster Kubernetes sem utilizar o Docker no RedHat

## Instalando Kubernetes com containerd e runc sem o Docker

```bash
curl -fsSL https://github.com/paliari-ti/dev-ops/blob/master/kubernetes/install.sh | bash
```
After the installation finished, follow the steps below

## Only on MASTER

```bash
kubeadm init --cri-socket /run/containerd/containerd.sock
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
kubectl get nodes
```

If you want to allow to run pods on master `kubectl taint nodes --all node-role.kubernetes.io/master-`

## Only on WORKERS
kubeadm join 172.31.24.131:6443 --token j7mbas.7kdapzfnifgfwmfl --discovery-token-ca-cert-hash sha256:b2bff6c78f2c29464154bd0bdd564ec63d243b94810e09a5b7fa0da02928425c --cri-socket /run/containerd/containerd.sock

