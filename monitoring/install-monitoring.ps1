# PowerShell Script para instalar stack de monitorización

$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Green
Write-Host "Instalando Stack de Monitorización" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

# Verificar Helm
if (!(Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Helm no está instalado" -ForegroundColor Red
    Write-Host "Por favor instala Helm desde: https://helm.sh/docs/intro/install/" -ForegroundColor Yellow
    exit 1
}

# Agregar repositorios
Write-Host "Agregando repositorios de Helm..." -ForegroundColor Yellow
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Cambiar al directorio del script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

# Crear namespace
Write-Host ""
Write-Host "Creando namespace de monitorización..." -ForegroundColor Yellow
kubectl apply -f namespace.yaml

# Instalar Prometheus Stack
Write-Host ""
Write-Host "Instalando Prometheus Stack..." -ForegroundColor Yellow
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack `
  --namespace monitoring `
  --set prometheus.prometheusSpec.retention=30d `
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]=ReadWriteOnce `
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi `
  --set grafana.adminPassword=admin `
  --set grafana.persistence.enabled=true `
  --set grafana.persistence.size=10Gi `
  --set grafana.service.type=LoadBalancer `
  --set alertmanager.enabled=true `
  --wait

# Esperar a que los pods estén listos
Write-Host ""
Write-Host "Esperando a que los pods estén listos..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "Instalación completada" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

# Información de acceso
Write-Host "Información de acceso:" -ForegroundColor Cyan
Write-Host ""

Write-Host "Grafana:" -ForegroundColor Yellow
$grafanaUrl = kubectl get svc prometheus-stack-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
Write-Host "  URL: http://$grafanaUrl"
Write-Host "  Usuario: admin"
Write-Host "  Contraseña: admin"
Write-Host ""

Write-Host "Prometheus:" -ForegroundColor Yellow
Write-Host "  Port-forward: kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090"
Write-Host "  Luego acceder a: http://localhost:9090"
Write-Host ""

Write-Host "Alertmanager:" -ForegroundColor Yellow
Write-Host "  Port-forward: kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-alertmanager 9093:9093"
Write-Host "  Luego acceder a: http://localhost:9093"
Write-Host ""

Write-Host "Para ver los pods de monitorización:" -ForegroundColor Cyan
Write-Host "  kubectl get pods -n monitoring"
