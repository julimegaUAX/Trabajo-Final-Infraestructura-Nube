# PowerShell Script para instalar Metrics Server en EKS

$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Green
Write-Host "Instalando Metrics Server" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

# Verificar kubectl
if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "Error: kubectl no está instalado" -ForegroundColor Red
    Write-Host "Por favor instala kubectl desde: https://kubernetes.io/docs/tasks/tools/" -ForegroundColor Yellow
    exit 1
}

# Verificar conexión al cluster
Write-Host "Verificando conexión al cluster..." -ForegroundColor Yellow
try {
    kubectl cluster-info | Out-Null
    Write-Host "✓ Conectado al cluster" -ForegroundColor Green
} catch {
    Write-Host "Error: No se puede conectar al cluster de Kubernetes" -ForegroundColor Red
    Write-Host "Verifica tu configuración con: kubectl config view" -ForegroundColor Yellow
    exit 1
}

# Instalar Metrics Server
Write-Host ""
Write-Host "Instalando Metrics Server..." -ForegroundColor Yellow
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Esperar a que el deployment esté listo
Write-Host ""
Write-Host "Esperando a que Metrics Server esté listo..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Verificar el estado
Write-Host ""
Write-Host "Verificando estado de Metrics Server..." -ForegroundColor Yellow
kubectl get deployment metrics-server -n kube-system

Write-Host ""
Write-Host "Esperando a que los pods estén listos..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=120s

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "Instalación completada" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

# Verificar que funciona
Write-Host "Verificando que Metrics Server funciona correctamente..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Esperando 30 segundos para que se recopilen métricas..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host ""
Write-Host "Métricas de nodos:" -ForegroundColor Cyan
kubectl top nodes

Write-Host ""
Write-Host "Métricas de pods (namespace cloudedu-services):" -ForegroundColor Cyan
kubectl top pods -n cloudedu-services

Write-Host ""
Write-Host "✓ Metrics Server está funcionando correctamente" -ForegroundColor Green
Write-Host ""
Write-Host "Ahora el HPA puede usar métricas de CPU/memoria en tiempo real" -ForegroundColor Cyan
Write-Host "Verifica el HPA con: kubectl get hpa -n cloudedu-services" -ForegroundColor Yellow
