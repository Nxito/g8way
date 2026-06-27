# ExternalSecrets + Hashicorp Vault

## 1. Instalar External Secrets Operator

```bash
microk8s helm install external-secrets external-secrets/external-secrets  -n external-secrets --create-namespace
```

## 2. Crear el token de acceso a Vault

En la UI de Vault: `Access` → `Tokens` → crear token con política de lectura sobre `secret/`.

```bash
kubectl create secret generic vault-token --from-literal=token="TUTOKEN" -n external-secrets
```

Verificar:
```bash
kubectl get secret vault-token -n external-secrets
```

## 3. Crear el ClusterSecretStore

```bash
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://192.168.50.200:8200"
      path: "secret"
      version: "v2"
      auth:
        tokenSecretRef:
          name: vault-token
          namespace: external-secrets
          key: token
EOF
```

Verificar:
```bash
kubectl get clustersecretstore vault-backend
```

## 4. Estructura de paths en Vault

| Path | Claves |
|------|--------|
| `secret/cloudflare/tunnel` | `token` |
| `secret/oauth2-proxy` | `client-id`, `client-secret`, `cookie-secret` |
| `secret/keycloak/db` | `username`, `password`, `database` |
| `secret/keycloak/admin` | `username`, `password` |

## 5. Verificar un ExternalSecret

```bash
kubectl get externalsecret -A
kubectl describe externalsecret <nombre> -n <namespace>
```

El campo `Status` debe mostrar `SecretSynced`.