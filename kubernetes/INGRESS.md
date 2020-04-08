## Docs to configure Nginx ingress controller and ingress with tls


### References

- [complete-tutorial](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-on-digitalocean-kubernetes-using-helm)
- [nginx-ingress](https://hub.helm.sh/charts/stable/nginx-ingress)
- [cert-manager](https://cert-manager.io/docs/usage/ingress/)


### Step 1 - Installing the Kubernetes Nginx Ingress Controller

```bash
kubectl create namespace ingress

helm install reverse-proxy stable/nginx-ingress --set rbac.create=true --set controller.publishService.enabled=true --set controller.metrics.enabled=true -n ingress
```

### Step 2 - Securing the Ingress Using Cert-Manager

```bash
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.14.1/cert-manager.crds.yaml

kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager --version v0.14.1 --namespace cert-manager jetstack/cert-manager
```

#### Create a basic ACME cluster issuer

[Reference](https://cert-manager.io/docs/configuration/acme/#creating-a-basic-acme-issuer)

`cluster-issue.yaml`
```yaml
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    email: daniel@paliari.com.br
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-private-key
    solvers:
    - http01:
        ingress:
          class: nginx
```

```bash
kubectl create -f cluster-issue.yaml
```

### Step 3 - Create an Ingress resource with tls enabled

`ingress.yaml`
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt
  name: your-ingress
spec:
  rules:
  - host: your.host.com
    http:
      paths:
      - backend:
          serviceName: your-service
          servicePort: 80
        path: /service-path
  tls:
  - hosts:
    - your.host.com
    secretName: your-ingress-tls
```

```bash
kubeclt -n your-service-namespace apply -f ingress.yaml
```