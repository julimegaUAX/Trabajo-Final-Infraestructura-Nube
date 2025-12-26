#!/bin/bash

# Script para instalar Metrics Server en EKS

set -e

echo "======================================"
echo "Instalando Metrics Server"
echo "======================================"
echo ""

# Verificar que kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl no está instalado"
    echo "Por favor instala kubectl desde: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Verificar conexión al cluster
echo "Verificando conexión al cluster..."
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: No se puede conectar al cluster de Kubernetes"
    echo "Verifica tu configuración con: kubectl config view"
    exit 1
fi
echo "✓ Conectado al cluster"

# Instalar Metrics Server
echo ""
echo "Instalando Metrics Server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Esperar a que el deployment esté listo
echo ""
echo "Esperando a que Metrics Server esté listo..."
sleep 10

# Verificar el estado
echo ""
echo "Verificando estado de Metrics Server..."
kubectl get deployment metrics-server -n kube-system

echo ""
echo "Esperando a que los pods estén listos..."
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=120s

echo ""
echo "======================================"
echo "Instalación completada"
echo "======================================"
echo ""

# Verificar que funciona
echo "Verificando que Metrics Server funciona correctamente..."
echo ""
echo "Esperando 30 segundos para que se recopilen métricas..."
sleep 30

echo ""
echo "Métricas de nodos:"
kubectl top nodes

echo ""
echo "Métricas de pods (namespace cloudedu-services):"
kubectl top pods -n cloudedu-services

echo ""
echo "✓ Metrics Server está funcionando correctamente"
echo ""
echo "Ahora el HPA puede usar métricas de CPU/memoria en tiempo real"
echo "Verifica el HPA con: kubectl get hpa -n cloudedu-services"
