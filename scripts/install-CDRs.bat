@echo off
REM Project: g8way
REM Author: Xito
REM License: Apache License 2.0
REM Bootstrap: instala CRDs e infraestructura base del cluster

echo Gateway API CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/standard-install.yaml
if %errorlevel% neq 0 goto error

echo MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/main/config/manifests/metallb-native.yaml
if %errorlevel% neq 0 goto error
kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s
if %errorlevel% neq 0 goto error

echo cert-manager
helm repo add jetstack https://charts.jetstack.io --force-update
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true --wait
if %errorlevel% neq 0 goto error

echo trust-manager
helm upgrade --install trust-manager jetstack/trust-manager --namespace cert-manager --wait
if %errorlevel% neq 0 goto error

echo Traefik
helm repo add traefik https://helm.traefik.io/traefik --force-update
helm upgrade --install traefik traefik/traefik --namespace traefik --create-namespace --wait
if %errorlevel% neq 0 goto error

echo External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io --force-update
helm upgrade --install external-secrets external-secrets/external-secrets --namespace external-secrets --create-namespace --wait
if %errorlevel% neq 0 goto error

echo Bootstrap completo
goto end

:error
echo ERROR: el bootstrap ha fallado en el paso anterior
exit /b 1

:end