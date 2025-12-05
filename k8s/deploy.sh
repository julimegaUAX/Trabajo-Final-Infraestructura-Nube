#!/bin/bash

# Script de despliegue para CloudEdu Services en Kubernetes
# Este script despliega todos los recursos necesarios en el orden correcto

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}CloudEdu Services - Despliegue K8s${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# Verificar que kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl no está instalado${NC}"
    exit 1
fi

# Verificar conexión al cluster
echo -e "${YELLOW}Verificando conexión al cluster...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: No se puede conectar al cluster de Kubernetes${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Conexión al cluster exitosa${NC}"
echo ""

# Función para aplicar manifiestos
apply_manifest() {
    local file=$1
    local description=$2
    
    echo -e "${YELLOW}Aplicando: ${description}${NC}"
    kubectl apply -f "$file"
    echo -e "${GREEN}✓ ${description} aplicado${NC}"
    echo ""
}

# 1. Crear namespace
apply_manifest "namespace.yaml" "Namespace"

# 2. Crear StorageClass
apply_manifest "storageclass.yaml" "StorageClass"

# 3. Crear PVC
apply_manifest "pvc.yaml" "PersistentVolumeClaim"

# Esperar a que el PVC esté bound (con timeout)
echo -e "${YELLOW}Esperando a que el PVC esté disponible...${NC}"
kubectl wait --for=condition=Bound pvc/cloudedu-data-pvc -n cloudedu-services --timeout=300s || true
echo ""

# 4. Crear ConfigMap y Secrets
apply_manifest "configmap.yaml" "ConfigMap y Secrets"

# 5. Crear RBAC
apply_manifest "rbac.yaml" "RBAC (Roles y ServiceAccount)"

# 6. Crear Deployment
apply_manifest "deployment.yaml" "Deployment"

# Esperar a que el deployment esté listo
echo -e "${YELLOW}Esperando a que los pods estén listos...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/cloudedu-app -n cloudedu-services
echo -e "${GREEN}✓ Pods listos${NC}"
echo ""

# 7. Crear Services
apply_manifest "service.yaml" "Services"

# 8. Crear HPA
apply_manifest "hpa.yaml" "HorizontalPodAutoscaler"

# 9. Crear Network Policy
apply_manifest "networkpolicy.yaml" "NetworkPolicy"

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Despliegue completado exitosamente${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# Mostrar información del despliegue
echo -e "${YELLOW}Información del despliegue:${NC}"
echo ""

echo -e "${YELLOW}Pods:${NC}"
kubectl get pods -n cloudedu-services -o wide

echo ""
echo -e "${YELLOW}Services:${NC}"
kubectl get svc -n cloudedu-services

echo ""
echo -e "${YELLOW}PVC:${NC}"
kubectl get pvc -n cloudedu-services

echo ""
echo -e "${YELLOW}HPA:${NC}"
kubectl get hpa -n cloudedu-services

echo ""
echo -e "${GREEN}Para obtener la URL del Load Balancer, ejecute:${NC}"
echo "kubectl get svc cloudedu-service -n cloudedu-services -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"

echo ""
echo -e "${GREEN}Para ver los logs, ejecute:${NC}"
echo "kubectl logs -f deployment/cloudedu-app -n cloudedu-services"
