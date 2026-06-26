RESUMEN GENERADO POR IA

# 🛡️ Infraestructura de Certificados: cert-manager + trust-manager

Sistema de gestión de identidades para el clúster microk8s. Aquí centralizamos la CA raíz, la generación de certificados hijos para los namespaces (`portainer`, `applications`, `authorization`) y la distribución automática de confianza.

## 🚀 Setup del Entorno

### 1. Instalación de Componentes
Primero, necesitamos los controladores en el clúster.

```bash
# Añadir repos de Helm
microk8s helm repo add jetstack [https://charts.jetstack.io](https://charts.jetstack.io)
microk8s helm repo update

# 1. Instalar cert-manager
microk8s helm install cert-manager jetstack/trust-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true

# 2. Instalar trust-manager (El repartidor de CA)
microk8s helm install trust-manager jetstack/trust-manager \
  --namespace cert-manager \
  --set app.trust.namespace=cert-manager
```

### 2. Despliegue de la Jerarquía (Orden de ejecución)
Sigue este orden exacto para que las dependencias no fallen:

1. **CA Raíz:** Crea el Issuer self-signed y la CA principal.
   ```bash
   kubectl apply -f cert-manager-CA.yaml
   ```
2. **Trust Bundle:** Configura el repartidor para que clone la CA en todos los namespaces.
   ```bash
   kubectl apply -f trust-manager.yaml
   ```
3. **Certificados Hijos:** Crea los certificados específicos para cada servicio.
   ```bash
   kubectl apply -f cert-manager-ns-portainer.yaml
   ```

---

## 🛠️ Arquitectura de Identidad

- **ClusterIssuer (`nxito-ca-issuer`):** La entidad certificadora global del clúster.
- **Bundle (`nxito-ca-bundle`):** Sincroniza el archivo `ca.crt` en todos los namespaces como un ConfigMap llamado `nxito-ca-bundle`.
- **Certificados:** Generados con algoritmo **ECDSA 256** para mayor seguridad y rendimiento.

---

## 💡 Ejemplo de Uso en Apps

Para que un pod confíe en otros servicios HTTPS del clúster, debe montar la CA distribuida por el trust-manager:

```yaml
spec:
  containers:
    - name: app-gamer
      volumeMounts:
        - name: ca-vol
          mountPath: /etc/ssl/certs/nxito-ca.crt
          subPath: nxito-ca.crt # Importante para no sobreescribir otros certs
          readOnly: true
  volumes:
    - name: ca-vol
      configMap:
        name: nxito-ca-bundle # Creado automáticamente por trust-manager
```

## 🔍 Comandos de Verificación
```bash
# Ver si el bundle se ha repartido bien
kubectl get configmap -A | grep nxito-ca-bundle

# Ver estado de los certificados
kubectl get certificate -A
```
---
**Nota:** Para exponer la CA fuera del clúster y descargarla en tu red local, usa el despliegue de Nginx que sirve el secret `nxito-ca-key-pair`.
 