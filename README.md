# g8way
Deploy with ArgoCD a k8s api-gateway solution with traefik, certmanager , keycloak and more


Al momento de este comit, estoy usando externamente un pihole y hasicorp vault externos en docker

El motivo: De moemnt ono creo que sean partes que deban ir a nivel de maquians / cluster


# Paso 1

Si has venido aqui, supongo tienes un entorno de kubernetes, digamos que eso era el paso 0

El paso 1 es instalar argoCD en dicho entorno
Para ello, esta preparado en 'apps/_argocd/readme.md' un helm con los pasos

# Paso 2

Necesitaras un vault o bóveda, para mantener seguros los secrets

Yo tengo el problema de que prefiero que mis secretos sean solo mios
Y como tampoco me gusta pagara a terceros para mis entornos personales, pues opté por hashicorp vault localmente

Puedes uasr AWS o AZURE para guardar tus secretos, que a nivel empresarial supongo es una opcion válida

Está preparado un docker compose en 'external/hashicorp-vault', dale un vistazo

Te recomiendo cambiar los certificados, genera unos nuevos

Tambien tendras que poner los secrets para config/secrets
Ejemplo:

```
 remoteRef:
        key: cloudflare/tunnel  <--- el path del secret creado
        property: token         <--- una de las propiedades del secret
```



# Paso 3


No se tu, pero yo uso una vpn tailscale y pi-hole para tenerles nombres fijos a mis rutas. De esta forma toda mi red tiene acceso a mis apps de administrador pero nadie externamente puede tocarlas ( a no  ser que se les crucen los cables en tailscale )

Tienes en docker compose un pi-hole preparado en la ruta 'external/pi-hole'
 


