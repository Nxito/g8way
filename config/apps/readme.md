
# Pasos para deployar Gateway API en microk8s

## Primero, instalar los CRD (Custom Resource Definition) del gateway

1. **Verifica qué CRD tienes:**

`microk8s kubectl get crd | grep gateway.networking.k8s.io`

Debería aparecer algo como:
```text
gatewayclasses.gateway.networking.k8s.io
gateways.gateway.networking.k8s.io
httproutes.gateway.networking.k8s.io
referencegrants.gateway.networking.k8s.io
```
*Si no tienes nada, ve al paso 2. Si ya los tienes, salta al paso 3.*

2. **Instalar los CRD oficiales:**

`microk8s kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml`

3. **Verificar el motor del Gateway:**

`microk8s kubectl get gatewayclass`

*Si está vacío, significa que el API está instalado pero no hay ningún controlador (como Traefik) gestionándolo.*

---

## Segundo, instalar Traefik habilitando Gateway API

### 1. Añadir repo y actualizar
`helm repo add traefik https://traefik.github.io/charts`
`helm repo update`

### 2. Configurar Traefik con IP fija (MetalLB)
Para que todo funcione, usamos un archivo `values.yaml`. Este archivo configura Traefik para usar los puertos correctos y asignarle una IP de tu red local mediante MetalLB.

**Crear `values.yaml`:**
```yaml
providers:
  kubernetesIngress:
    enabled: false
  kubernetesGateway:
    enabled: true

ports:
  web:
    port: 8000
    exposedPort: 80
    expose: 
      enabled: true 
  websecure:
    port: 8443
    exposedPort: 443
    expose: 
      enabled: true 

service:
  type: LoadBalancer
  annotations:
    # IP que le asignará MetalLB
    metallb.universe.tf/loadBalancerIP: 192.168.50.201 
  externalTrafficPolicy: Local
  
gateway:
  enabled: true   
  name: traefik-gateway
  listeners:
    https:
      port: 8443
      protocol: HTTPS
      allowedRoutes:
        namespaces:
          from: All
      tls:
        mode: Terminate
        certificateRefs:
          - name: nxito-local-tls
            kind: Secret
            namespace: applications
```

### 3. Ejecutar la instalación
`helm upgrade --install traefik traefik/traefik -f values.yaml -n traefik --create-namespace`

---

## Tercero, configurar Rutas y Certificados

En este punto, el Gateway ya tiene la IP `.201`, pero necesitamos decirle qué hacer cuando llegue una petición a `nxito.local`.

### 1. El manifiesto de la Ruta (HTTPRoute)
Este archivo conecta el dominio con tu aplicación (ej: Homepage).

**Crear `homepage-route.yaml`:**
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: homepage-route
  namespace: applications
spec:
  parentRefs:
  - name: traefik-gateway
    namespace: traefik
    sectionName: https    # Nombre del listener en el values.yaml
  hostnames:
  - "nxito.local"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: homepage
      port: 3000
```

### 2. Permiso de acceso al Certificado (ReferenceGrant)
Como el Gateway está en el namespace `traefik` y el certificado está en `applications`, necesitamos dar permiso de lectura:

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-traefik-to-secrets
  namespace: applications
spec:
  from:
  - group: gateway.networking.k8s.io
    kind: Gateway
    namespace: traefik
  to:
  - group: ""
    kind: Secret
    name: nxito-local-tls
```

---

## Verificación Final

1. **Comprobar Gateway:** `microk8s kubectl get gateway -n traefik` (Debe decir `PROGRAMMED: True`).
2. **Comprobar IP:** El servicio `traefik` en el namespace `traefik` debe tener la IP externa configurada en el `values.yaml`.
3. **Prueba de fuego:**
   `curl -Ik -H "Host: nxito.local" https://192.168.50.201`

Si el comando devuelve un **HTTP 200** con next.js, ¡el despliegue ha sido un éxito! ✅


## Extras
como las aplicaciones van por hostname, para integrar con servicios como tailscale solo hay que poner el https el nombre puesto en 
 hostnames:
  - "nxito.local"

  si quieres poner otro dominio como cloudflare, configura un tunnel y pon algo como
   hostnames:
  - "nxito.local"
  - "nxito.com"

  o solo el ultimo parafiltrar tus servicios privados... como navidrome para el streaming de musica 100% legalmente legal


# 404 nginx?
eso es ingress de microk8s apoderandose de nuevo del puerto 80 y 443...
esto esta mal elaborado por parte de microk8s...
sudo snap refresh microk8s --hold
si instalaste con snap, cancela la actualizacion automatica... por que parece que reinstala ingress