# PowerShell Script para despliegue en Kubernetes
# CloudEdu Services - Windows deployment script

param(
    [switch]$SkipWait = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=====================================" -ForegroundColor Green
Write-Host "CloudEdu Services - Despliegue K8s" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# Verificar kubectl
if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "Error: kubectl no está instalado" -ForegroundColor Red
    exit 1
}

# Verificar conexión al cluster
Write-Host "Verificando conexión al cluster..." -ForegroundColor Yellow
try {
    kubectl cluster-info | Out-Null
    Write-Host "✓ Conexión al cluster exitosa" -ForegroundColor Green
} catch {
    Write-Host "Error: No se puede conectar al cluster de Kubernetes" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Función para aplicar manifiestos
function Apply-Manifest {
    param(
        [string]$File,
        [string]$Description
    )
    
    Write-Host "Aplicando: $Description" -ForegroundColor Yellow
    kubectl apply -f $File
    Write-Host "✓ $Description aplicado" -ForegroundColor Green
    Write-Host ""
}

# Cambiar al directorio de k8s
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

# 1. Crear namespace
Apply-Manifest -File "namespace.yaml" -Description "Namespace"

# 2. Crear StorageClass
Apply-Manifest -File "storageclass.yaml" -Description "StorageClass"

# 3. Crear PVC
Apply-Manifest -File "pvc.yaml" -Description "PersistentVolumeClaim"

# Esperar a que el PVC esté bound
if (!$SkipWait) {
    Write-Host "Esperando a que el PVC esté disponible..." -ForegroundColor Yellow
    kubectl wait --for=condition=Bound pvc/cloudedu-data-pvc -n cloudedu-services --timeout=300s
    Write-Host ""
}

# 4. Crear ConfigMap y Secrets
Apply-Manifest -File "configmap.yaml" -Description "ConfigMap y Secrets"

# 5. Crear RBAC
Apply-Manifest -File "rbac.yaml" -Description "RBAC (Roles y ServiceAccount)"

# 6. Crear Deployment
Apply-Manifest -File "deployment.yaml" -Description "Deployment"

# Esperar a que el deployment esté listo
if (!$SkipWait) {
    Write-Host "Esperando a que los pods estén listos..." -ForegroundColor Yellow
    kubectl wait --for=condition=available --timeout=300s deployment/cloudedu-app -n cloudedu-services
    Write-Host "✓ Pods listos" -ForegroundColor Green
    Write-Host ""
}

# 7. Crear Services
Apply-Manifest -File "service.yaml" -Description "Services"

# 8. Crear HPA
Apply-Manifest -File "hpa.yaml" -Description "HorizontalPodAutoscaler"

# 9. Crear Network Policy
Apply-Manifest -File "networkpolicy.yaml" -Description "NetworkPolicy"

Write-Host "=====================================" -ForegroundColor Green
Write-Host "Despliegue completado exitosamente" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# Mostrar información del despliegue
Write-Host "Información del despliegue:" -ForegroundColor Yellow
Write-Host ""

Write-Host "Pods:" -ForegroundColor Yellow
kubectl get pods -n cloudedu-services -o wide

Write-Host ""
Write-Host "Services:" -ForegroundColor Yellow
kubectl get svc -n cloudedu-services

Write-Host ""
Write-Host "PVC:" -ForegroundColor Yellow
kubectl get pvc -n cloudedu-services

Write-Host ""
Write-Host "HPA:" -ForegroundColor Yellow
kubectl get hpa -n cloudedu-services

Write-Host ""
Write-Host "Para obtener la URL del Load Balancer, ejecute:" -ForegroundColor Green
Write-Host 'kubectl get svc cloudedu-service -n cloudedu-services -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"'

Write-Host ""
Write-Host "Para ver los logs, ejecute:" -ForegroundColor Green
Write-Host "kubectl logs -f deployment/cloudedu-app -n cloudedu-services"
