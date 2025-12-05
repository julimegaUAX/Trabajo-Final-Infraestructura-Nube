#!/bin/bash

# Script para verificar el estado de salud de CloudEdu Services

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "======================================"
echo "CloudEdu Services - Health Check"
echo "======================================"
echo ""

# Función para verificar comando exitoso
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
        return 0
    else
        echo -e "${RED}✗ $1${NC}"
        return 1
    fi
}

# 1. Verificar kubectl
echo "1. Verificando herramientas..."
kubectl version --client > /dev/null 2>&1
check_status "kubectl instalado"

# 2. Verificar conexión al cluster
echo ""
echo "2. Verificando cluster de Kubernetes..."
kubectl cluster-info > /dev/null 2>&1
check_status "Conexión al cluster EKS"

# 3. Verificar nodos
echo ""
echo "3. Estado de los nodos:"
NODES_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c Ready || echo "0")
NODES_TOTAL=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "0")
echo "   Nodos listos: $NODES_READY / $NODES_TOTAL"
if [ "$NODES_READY" -gt 0 ]; then
    echo -e "${GREEN}✓ Nodos funcionando${NC}"
else
    echo -e "${RED}✗ No hay nodos listos${NC}"
fi

# 4. Verificar namespace
echo ""
echo "4. Verificando namespace cloudedu-services..."
kubectl get namespace cloudedu-services > /dev/null 2>&1
check_status "Namespace existe"

# 5. Verificar pods
echo ""
echo "5. Estado de los pods:"
PODS_RUNNING=$(kubectl get pods -n cloudedu-services --no-headers 2>/dev/null | grep -c Running || echo "0")
PODS_TOTAL=$(kubectl get pods -n cloudedu-services --no-headers 2>/dev/null | wc -l || echo "0")
echo "   Pods running: $PODS_RUNNING / $PODS_TOTAL"

kubectl get pods -n cloudedu-services 2>/dev/null || echo "   No pods found"

if [ "$PODS_RUNNING" -gt 0 ]; then
    echo -e "${GREEN}✓ Pods en ejecución${NC}"
else
    echo -e "${RED}✗ No hay pods en ejecución${NC}"
fi

# 6. Verificar PVC
echo ""
echo "6. Verificando almacenamiento persistente..."
PVC_STATUS=$(kubectl get pvc -n cloudedu-services -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")
echo "   PVC Status: $PVC_STATUS"
if [ "$PVC_STATUS" == "Bound" ]; then
    echo -e "${GREEN}✓ PVC vinculado correctamente${NC}"
else
    echo -e "${YELLOW}⚠ PVC no está bound${NC}"
fi

# 7. Verificar servicios
echo ""
echo "7. Verificando servicios..."
kubectl get svc -n cloudedu-services 2>/dev/null
LB_HOSTNAME=$(kubectl get svc cloudedu-service -n cloudedu-services -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
if [ -n "$LB_HOSTNAME" ]; then
    echo -e "${GREEN}✓ Load Balancer configurado${NC}"
    echo "   URL: http://$LB_HOSTNAME"
else
    echo -e "${YELLOW}⚠ Load Balancer no disponible aún${NC}"
fi

# 8. Verificar HPA
echo ""
echo "8. Verificando HorizontalPodAutoscaler..."
kubectl get hpa -n cloudedu-services 2>/dev/null
HPA_EXISTS=$(kubectl get hpa -n cloudedu-services --no-headers 2>/dev/null | wc -l || echo "0")
if [ "$HPA_EXISTS" -gt 0 ]; then
    echo -e "${GREEN}✓ HPA configurado${NC}"
else
    echo -e "${YELLOW}⚠ HPA no encontrado${NC}"
fi

# 9. Verificar monitorización
echo ""
echo "9. Verificando sistema de monitorización..."
PROMETHEUS_RUNNING=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers 2>/dev/null | grep -c Running || echo "0")
GRAFANA_RUNNING=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers 2>/dev/null | grep -c Running || echo "0")

echo "   Prometheus pods: $PROMETHEUS_RUNNING"
echo "   Grafana pods: $GRAFANA_RUNNING"

if [ "$PROMETHEUS_RUNNING" -gt 0 ] && [ "$GRAFANA_RUNNING" -gt 0 ]; then
    echo -e "${GREEN}✓ Monitorización activa${NC}"
    
    GRAFANA_URL=$(kubectl get svc prometheus-stack-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ -n "$GRAFANA_URL" ]; then
        echo "   Grafana URL: http://$GRAFANA_URL"
    fi
else
    echo -e "${YELLOW}⚠ Monitorización no está completamente activa${NC}"
fi

# 10. Test de conectividad
echo ""
echo "10. Probando conectividad de la aplicación..."
if [ -n "$LB_HOSTNAME" ]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$LB_HOSTNAME/health 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo -e "${GREEN}✓ Aplicación responde correctamente (HTTP $HTTP_CODE)${NC}"
    else
        echo -e "${YELLOW}⚠ Aplicación no responde (HTTP $HTTP_CODE)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No se puede probar, Load Balancer no disponible${NC}"
fi

# Resumen
echo ""
echo "======================================"
echo "Resumen del Health Check"
echo "======================================"

OVERALL_STATUS="OK"

if [ "$NODES_READY" -eq 0 ] || [ "$PODS_RUNNING" -eq 0 ]; then
    OVERALL_STATUS="CRITICAL"
elif [ "$PVC_STATUS" != "Bound" ] || [ -z "$LB_HOSTNAME" ]; then
    OVERALL_STATUS="WARNING"
fi

case "$OVERALL_STATUS" in
    "OK")
        echo -e "${GREEN}Estado general: ✓ SALUDABLE${NC}"
        echo "Todos los componentes están funcionando correctamente."
        ;;
    "WARNING")
        echo -e "${YELLOW}Estado general: ⚠ ADVERTENCIA${NC}"
        echo "Algunos componentes requieren atención."
        ;;
    "CRITICAL")
        echo -e "${RED}Estado general: ✗ CRÍTICO${NC}"
        echo "Hay problemas críticos que requieren atención inmediata."
        ;;
esac

echo ""
echo "Para más detalles, ejecute:"
echo "  kubectl get all -n cloudedu-services"
echo "  kubectl describe pods -n cloudedu-services"
echo "  kubectl logs -f deployment/cloudedu-app -n cloudedu-services"
