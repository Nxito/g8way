# Vault para argoCD
Este archivo es para crear una bóveda centralizada para almacenar los secretos de K8s para ArgoCD
ArgoCD se usará de fuente de la verdad, pero manejar secretos en git es complejo
Se podria usar SOPS, pero al parecer los desarolladores se quejan de que literalmente es un "coñazo" para rotar contraseñas en caso de filtracion o cambio 
La otra opcion , com oes este caso es usar bóvedas como las de  AWS o AZURE, pero al parecer hashicorp permite que sea gratis y lcoal.
Si se tiene servidor propio separado de K8s, es una opcion mas que viable


## Una seguridad minima

Por el momento se asignara un TLS a mano,quedure 10 añitos, por cifrar la conexion anda mas aun que se nos queje el navegador

en la carpeta certs meteremos el cert

openssl req -x509 -newkey rsa:4096 -sha256 -days 36500 -nodes \
  -keyout certs/vault.key \
  -out certs/vault.crt \
  -subj "/CN=vault" \
  -addext "subjectAltName=IP:127.0.0.1,DNS:vault,DNS:localhost"

chmod 644 certs/vault.crt
chmod 644 certs/vault.key

## Configurar al inicio

1. Inicializar — la propia UI te pregunta cuántas claves quieres. Pon 1 en ambos campos para simplificar. Descarga o copia las claves que te da.
2. Unseal — pega la clave que acabas de copiar, que esta en base 64.
3. Login — usa el root token que te dio el paso 1.
4. Habilitar KV store — ve a Secrets → Enable new engine → KV , versión 2, path secret.
5. Meter secretos — Secrets → secret → Create secret, rellenas el path (ej. myapp) y añades los pares clave/valor que quieras.

## Listar keys actuales de k8s

kubectl get secrets --all-namespaces -o json | jq '[.items[] | select(.type=="Opaque") | select(.data != null) | {
  name: .metadata.name,
  namespace: .metadata.namespace,
  data: (.data | map_values(@base64d))
}]' > secrets-export.json


