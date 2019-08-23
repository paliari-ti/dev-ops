# Extras

## Red Hat

### Configurar **yum**

```
subscription-manager register --username <username> --password <password> --auto-attach

subscription-manager repos --enable=rhel-7-server-rpms
subscription-manager repos --enable=rhel-7-server-extras-rpms
subscription-manager repos --enable=rhel-7-server-optional-rpms

```

```
yum update -y
```

### Disable swap

```
swapoff -a
```
Remove the line with `/dev/mapper/rhel-swap` from `/etc/fstab` file

## K8S

[Bash completion](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-bash-completion)

```bash
# Requirements
yum install bash-completion -y
echo 'source /usr/share/bash-completion/bash_completion' >> ~/.bashrc

echo 'source <(kubectl completion bash)' >>~/.bashrc
kubectl completion bash >/etc/bash_completion.d/kubectl
```

## MetalLb

[Oficial docs](https://metallb.universe.tf/installation/)

[Tutorial](https://www.youtube.com/watch?v=xYiYIjlAgHY)

```bash
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.1/manifests/metallb.yaml
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