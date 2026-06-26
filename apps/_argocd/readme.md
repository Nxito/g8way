# Preparar argoCD 

Se prepara argoCD primero, ya que será la base para levantar lo demas

## 1. Namespace

```bash
kubectl create namespace argocd
```

## 2. Añadir repo helm

```bash
 helm repo add argo https://argoproj.github.io/argo-helm
 helm repo update
```

## 3. Instalar con tu values

```bash
 helm install argocd argo/argo-cd  -n argocd  -f values.yaml
```

## 4. Verificar

```bash
kubectl get pods -n argocd
```

> Como esta en modo clusterIP y se pasará seguramente a nombre de dominio .local, se accederá sin node IP de esta forma

## 5.Port-forward

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

## Recuperar contraseña generada

```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```
