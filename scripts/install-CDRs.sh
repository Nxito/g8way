#!/bin/bash
# Project: g8way
# Author: Xito
# License: Apache License 2.0
# Bootstrap: instala CRDs e infraestructura base del cluster

set -e

echo "==> Gateway API CRDs"
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/standard-install.yaml

echo "==> MetalLB"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/main/config/manifests/metallb-native.yaml
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s

echo "==> cert-manager"
helm repo add jetstack https://charts.jetstack.io --force-update
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true \
  --wait

echo "==> trust-manager"
helm upgrade --install trust-manager jetstack/trust-manager \
  --namespace cert-manager \
  --wait

echo "==> Traefik"
helm repo add traefik https://helm.traefik.io/traefik --force-update
helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --wait

echo "==> External Secrets Operator"
helm repo add external-secrets https://charts.external-secrets.io --force-update
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --wait

echo "==> Bootstrap completo"