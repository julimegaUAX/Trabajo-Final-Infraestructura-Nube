# Script de Health Check para CloudEdu Services (PowerShell)

$ErrorActionPreference = "Continue"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "CloudEdu Services - Health Check" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

function Test-Status {
    param($Message, $Condition)
    if ($Condition) {
        Write-Host "✓ $Message" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ $Message" -ForegroundColor Red
        return $false
    }
}

# 1. Verificar kubectl
Write-Host "1. Verificando herramientas..." -ForegroundColor Yellow
$kubectlExists = Get-Command kubectl -ErrorAction SilentlyContinue
Test-Status "kubectl instalado" ($null -ne $kubectlExists)

# 2. Verificar conexión al cluster
Write-Host ""
Write-Host "2. Verificando cluster de Kubernetes..." -ForegroundColor Yellow
try {
    kubectl cluster-info | Out-Null
    Test-Status "Conexión al cluster EKS" $true
} catch {
    Test-Status "Conexión al cluster EKS" $false
}

# 3. Verificar nodos
Write-Host ""
Write-Host "3. Estado de los nodos:" -ForegroundColor Yellow
$nodes = kubectl get nodes --no-headers 2>$null
$nodesReady = ($nodes | Select-String "Ready" | Measure-Object).Count
$nodesTotal = ($nodes | Measure-Object).Count
Write-Host "   Nodos listos: $nodesReady / $nodesTotal"
if ($nodesReady -gt 0) {
    Write-Host "✓ Nodos funcionando" -ForegroundColor Green
} else {
    Write-Host "✗ No hay nodos listos" -ForegroundColor Red
}

# 4. Verificar namespace
Write-Host ""
Write-Host "4. Verificando namespace cloudedu-services..." -ForegroundColor Yellow
try {
    kubectl get namespace cloudedu-services 2>$null | Out-Null
    Test-Status "Namespace existe" $true
} catch {
    Test-Status "Namespace existe" $false
}

# 5. Verificar pods
Write-Host ""
Write-Host "5. Estado de los pods:" -ForegroundColor Yellow
$pods = kubectl get pods -n cloudedu-services --no-headers 2>$null
$podsRunning = ($pods | Select-String "Running" | Measure-Object).Count
$podsTotal = ($pods | Measure-Object).Count
Write-Host "   Pods running: $podsRunning / $podsTotal"

kubectl get pods -n cloudedu-services 2>$null

if ($podsRunning -gt 0) {
    Write-Host "✓ Pods en ejecución" -ForegroundColor Green
} else {
    Write-Host "✗ No hay pods en ejecución" -ForegroundColor Red
}

# 6. Verificar PVC
Write-Host ""
Write-Host "6. Verificando almacenamiento persistente..." -ForegroundColor Yellow
try {
    $pvcStatus = kubectl get pvc -n cloudedu-services -o jsonpath='{.items[0].status.phase}' 2>$null
    Write-Host "   PVC Status: $pvcStatus"
    if ($pvcStatus -eq "Bound") {
        Write-Host "✓ PVC vinculado correctamente" -ForegroundColor Green
    } else {
        Write-Host "⚠ PVC no está bound" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠ No se pudo verificar PVC" -ForegroundColor Yellow
}

# 7. Verificar servicios
Write-Host ""
Write-Host "7. Verificando servicios..." -ForegroundColor Yellow
kubectl get svc -n cloudedu-services 2>$null

try {
    $lbHostname = kubectl get svc cloudedu-service -n cloudedu-services -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
    if ($lbHostname) {
        Write-Host "✓ Load Balancer configurado" -ForegroundColor Green
        Write-Host "   URL: http://$lbHostname"
    } else {
        Write-Host "⚠ Load Balancer no disponible aún" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠ No se pudo obtener URL del Load Balancer" -ForegroundColor Yellow
}

# 8. Verificar HPA
Write-Host ""
Write-Host "8. Verificando HorizontalPodAutoscaler..." -ForegroundColor Yellow
kubectl get hpa -n cloudedu-services 2>$null
$hpa = kubectl get hpa -n cloudedu-services --no-headers 2>$null
if ($hpa) {
    Write-Host "✓ HPA configurado" -ForegroundColor Green
} else {
    Write-Host "⚠ HPA no encontrado" -ForegroundColor Yellow
}

# 9. Verificar monitorización
Write-Host ""
Write-Host "9. Verificando sistema de monitorización..." -ForegroundColor Yellow
$prometheusPods = kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers 2>$null
$grafanaPods = kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers 2>$null

$prometheusRunning = ($prometheusPods | Select-String "Running" | Measure-Object).Count
$grafanaRunning = ($grafanaPods | Select-String "Running" | Measure-Object).Count

Write-Host "   Prometheus pods: $prometheusRunning"
Write-Host "   Grafana pods: $grafanaRunning"

if ($prometheusRunning -gt 0 -and $grafanaRunning -gt 0) {
    Write-Host "✓ Monitorización activa" -ForegroundColor Green
    
    try {
        $grafanaUrl = kubectl get svc prometheus-stack-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
        if ($grafanaUrl) {
            Write-Host "   Grafana URL: http://$grafanaUrl"
        }
    } catch {}
} else {
    Write-Host "⚠ Monitorización no está completamente activa" -ForegroundColor Yellow
}

# 10. Test de conectividad
Write-Host ""
Write-Host "10. Probando conectividad de la aplicación..." -ForegroundColor Yellow
if ($lbHostname) {
    try {
        $response = Invoke-WebRequest -Uri "http://$lbHostname/health" -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "✓ Aplicación responde correctamente (HTTP $($response.StatusCode))" -ForegroundColor Green
        } else {
            Write-Host "⚠ Aplicación responde con código HTTP $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠ No se pudo conectar a la aplicación" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ No se puede probar, Load Balancer no disponible" -ForegroundColor Yellow
}

# Resumen
Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Resumen del Health Check" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

$overallStatus = "OK"

if ($nodesReady -eq 0 -or $podsRunning -eq 0) {
    $overallStatus = "CRITICAL"
} elseif ($pvcStatus -ne "Bound" -or !$lbHostname) {
    $overallStatus = "WARNING"
}

switch ($overallStatus) {
    "OK" {
        Write-Host "Estado general: ✓ SALUDABLE" -ForegroundColor Green
        Write-Host "Todos los componentes están funcionando correctamente."
    }
    "WARNING" {
        Write-Host "Estado general: ⚠ ADVERTENCIA" -ForegroundColor Yellow
        Write-Host "Algunos componentes requieren atención."
    }
    "CRITICAL" {
        Write-Host "Estado general: ✗ CRÍTICO" -ForegroundColor Red
        Write-Host "Hay problemas críticos que requieren atención inmediata."
    }
}

Write-Host ""
Write-Host "Para más detalles, ejecute:" -ForegroundColor Cyan
Write-Host "  kubectl get all -n cloudedu-services"
Write-Host "  kubectl describe pods -n cloudedu-services"
Write-Host "  kubectl logs -f deployment/cloudedu-app -n cloudedu-services"
