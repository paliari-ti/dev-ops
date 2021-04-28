# Extras

## Red Hat

### Configurar **yum**

```
subscription-manager register --username <username> --password <password> --auto-attach

subscription-manager repos --enable=rhel-7-server-rpms
subscription-manager repos --enable=rhel-7-server-extras-rpms
subscription-manager repos --enable=rhel-7-server-optional-rpms

yum update -y
```

### Disable swap

```bash 
swapoff -a

# Comment the line with `/dev/mapper/rhel-swap` from `/etc/fstab` file
sed -i 's/\/dev\/mapper\/rhel-swap/#\/dev\/mapper\/rhel-swap/g' /etc/fstab
```

## [K8S bash completion](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-bash-completion)

```bash
# Requirements
yum install bash-completion -y
echo 'source /usr/share/bash-completion/bash_completion' >> ~/.bashrc

echo 'source <(kubectl completion bash)' >>~/.bashrc
kubectl completion bash >/etc/bash_completion.d/kubectl
```

## [Install Helm](https://helm.sh/docs/intro/install/#from-script)

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh

helm repo add stable https://charts.helm.sh/stable
helm repo update
```

## [MetalLb](https://metallb.universe.tf/installation/)

[Youtube tutorial](https://www.youtube.com/watch?v=xYiYIjlAgHY)

```bash
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml
```

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 192.168.25.111-192.168.25.113
EOF
```

## [Metrics Server](https://github.com/kubernetes-sigs/metrics-server)

```bash
kubectl -n kube-system apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl -n kube-system patch deployment metrics-server --type "json" -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
```

## External Users - Cluster Admin

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-cluster-admin
  namespace: default
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-cluster-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: external-cluster-admin
  namespace: default
EOF

# Get service account token
kubectl get secret $(kubectl get secret -o=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep external-cluster-admin) -o jsonpath={.data.token} | base64 -d
```
