#!/bin/bash

# Script para instalar stack de monitorización (Prometheus + Grafana)

set -e

echo "======================================"
echo "Instalando Stack de Monitorización"
echo "======================================"
echo ""

# Verificar que helm está instalado
if ! command -v helm &> /dev/null; then
    echo "Error: Helm no está instalado"
    echo "Instalando Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Agregar repositorios de Helm
echo "Agregando repositorios de Helm..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Crear namespace
echo ""
echo "Creando namespace de monitorización..."
kubectl apply -f namespace.yaml

# Instalar Prometheus Stack (incluye Prometheus, Alertmanager, Grafana, y varios exporters)
echo ""
echo "Instalando Prometheus Stack..."
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]=ReadWriteOnce \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
  --set grafana.adminPassword=admin \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.size=10Gi \
  --set grafana.service.type=LoadBalancer \
  --set alertmanager.enabled=true \
  --wait

# Esperar a que los pods estén listos
echo ""
echo "Esperando a que los pods estén listos..."
kubectl wait --for=condition=ready pod -l "release=prometheus-stack" -n monitoring --timeout=300s

echo ""
echo "======================================"
echo "Instalación completada"
echo "======================================"
echo ""

# Obtener información de acceso
echo "Información de acceso:"
echo ""

echo "Grafana:"
GRAFANA_URL=$(kubectl get svc prometheus-stack-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "  URL: http://$GRAFANA_URL"
echo "  Usuario: admin"
echo "  Contraseña: admin"
echo ""

echo "Prometheus:"
echo "  Port-forward: kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090"
echo "  Luego acceder a: http://localhost:9090"
echo ""

echo "Alertmanager:"
echo "  Port-forward: kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-alertmanager 9093:9093"
echo "  Luego acceder a: http://localhost:9093"
echo ""

echo "Para ver los pods de monitorización:"
echo "  kubectl get pods -n monitoring"
