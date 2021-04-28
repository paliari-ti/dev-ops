## Docs to configure Nginx ingress controller and ingress with tls

### Step 1 - Installing the Kubernetes Nginx Ingress Controller

[Reference](https://kubernetes.github.io/ingress-nginx/deploy/#using-helm)

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx
```

### Step 2 - Securing the Ingress Using Cert-Manager

[Reference](https://cert-manager.io/docs/usage/ingress/)

```bash
kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager --version v1.3.1 --set installCRDs=true --namespace cert-manager jetstack/cert-manager
```

#### Create a basic ACME cluster issuer

[Reference](https://cert-manager.io/docs/configuration/acme/#creating-a-basic-acme-issuer)

`cluster-issuer.yaml`
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    email: paliari@paliari.com.br
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-private-key
    solvers:
    - http01:
        ingress:
          class: nginx
```

```bash
kubectl create -f cluster-issuer.yaml
```

### Step 3 - Create an Ingress resource with tls enabled (Optional - only to test if everything is working)

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