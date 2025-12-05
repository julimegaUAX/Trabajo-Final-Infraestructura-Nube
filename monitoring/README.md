# Monitorización con Prometheus y Grafana

Este directorio contiene la configuración para el stack de monitorización de CloudEdu Services.

## Componentes

### 1. Prometheus
Sistema de monitorización y base de datos de series temporales.

**Características:**
- Almacenamiento de métricas durante 30 días
- Volumen persistente de 50Gi
- Scraping automático de pods con anotaciones

### 2. Grafana
Plataforma de visualización y análisis.

**Características:**
- Dashboards personalizados
- Alertas configurables
- Volumen persistente de 10Gi
- Acceso vía LoadBalancer

### 3. Alertmanager
Gestión y enrutamiento de alertas.

**Alertas configuradas:**
- Aplicación caída
- Uso alto de CPU (>80%)
- Uso alto de memoria (>80%)
- Reinicios frecuentes de pods
- PVC casi lleno (>80%)

## Instalación

### Usando el script automatizado:

**Linux/Mac:**
```bash
cd monitoring
chmod +x install-monitoring.sh
./install-monitoring.sh
```

**Windows (PowerShell):**
```powershell
cd monitoring
.\install-monitoring.ps1
```

### Instalación manual:

1. **Agregar repositorios de Helm:**
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

2. **Crear namespace:**
```bash
kubectl apply -f namespace.yaml
```

3. **Instalar Prometheus Stack:**
```bash
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
```

4. **Aplicar ServiceMonitor y alertas:**
```bash
kubectl apply -f servicemonitor.yaml
```

## Acceso

### Grafana
```bash
# Obtener URL del LoadBalancer
kubectl get svc prometheus-stack-grafana -n monitoring

# Credenciales por defecto
Usuario: admin
Contraseña: admin
```

**IMPORTANTE:** Cambiar la contraseña después del primer login.

### Prometheus
```bash
# Port-forward local
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090

# Acceder en el navegador
http://localhost:9090
```

### Alertmanager
```bash
# Port-forward local
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-alertmanager 9093:9093

# Acceder en el navegador
http://localhost:9093
```

## Dashboard de Grafana

### Importar dashboard personalizado:

1. Acceder a Grafana
2. Click en "+" → "Import"
3. Subir el archivo `grafana-dashboard.json`
4. Seleccionar datasource "Prometheus"
5. Click en "Import"

### Dashboard incluye:

- **Application Status**: Estado de la aplicación (up/down)
- **Request Rate**: Tasa de peticiones por segundo
- **CPU Usage**: Uso de CPU por pod
- **Memory Usage**: Uso de memoria por pod
- **Pod Restarts**: Número de reinicios de pods
- **PVC Usage**: Uso de almacenamiento persistente

## Métricas Disponibles

### Métricas de Kubernetes:
- `kube_pod_info`
- `kube_pod_status_phase`
- `kube_deployment_status_replicas`
- `kube_node_status_condition`

### Métricas de contenedores:
- `container_cpu_usage_seconds_total`
- `container_memory_usage_bytes`
- `container_network_receive_bytes_total`
- `container_network_transmit_bytes_total`

### Métricas de la aplicación:
- `http_requests_total`
- `http_request_duration_seconds`
- `process_cpu_seconds_total`
- `process_resident_memory_bytes`

## Consultas PromQL Útiles

### Ver pods running:
```promql
kube_pod_status_phase{namespace="cloudedu-services",phase="Running"}
```

### CPU usage por pod:
```promql
rate(container_cpu_usage_seconds_total{namespace="cloudedu-services"}[5m]) * 100
```

### Memoria usage por pod:
```promql
container_memory_usage_bytes{namespace="cloudedu-services"} / 1024 / 1024
```

### Request rate:
```promql
rate(http_requests_total{namespace="cloudedu-services"}[5m])
```

### Error rate:
```promql
rate(http_requests_total{namespace="cloudedu-services",status=~"5.."}[5m])
```

## Configuración de Alertas

### Modificar alertas existentes:
```bash
kubectl edit prometheusrule cloudedu-alerts -n cloudedu-services
```

### Añadir nueva alerta:
```yaml
- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "High error rate detected"
    description: "Error rate is above 10% for 5 minutes"
```

## Integración con Slack/Email

### Configurar Alertmanager para Slack:

1. Crear webhook en Slack
2. Editar configuración de Alertmanager:
```bash
kubectl edit secret alertmanager-prometheus-stack-kube-prom-alertmanager -n monitoring
```

3. Añadir configuración:
```yaml
receivers:
  - name: 'slack'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
        channel: '#alerts'
        title: 'CloudEdu Alert'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

## Troubleshooting

### Prometheus no está scrapando métricas:
```bash
# Verificar ServiceMonitor
kubectl get servicemonitor -n cloudedu-services

# Ver targets en Prometheus
# http://localhost:9090/targets
```

### Grafana no se conecta a Prometheus:
```bash
# Verificar que el datasource está configurado
kubectl get secret prometheus-stack-grafana -n monitoring -o yaml

# Verificar conectividad
kubectl exec -it deployment/prometheus-stack-grafana -n monitoring -- wget -O- http://prometheus-stack-kube-prom-prometheus:9090/-/healthy
```

### Alertas no se envían:
```bash
# Ver logs de Alertmanager
kubectl logs -f deployment/prometheus-stack-kube-prom-alertmanager -n monitoring

# Verificar configuración
kubectl get secret alertmanager-prometheus-stack-kube-prom-alertmanager -n monitoring -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d
```

## Recursos y Referencias

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Kube-Prometheus-Stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [PromQL Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)

## Mantenimiento

### Backup de dashboards:
```bash
# Exportar dashboard
kubectl get configmap -n monitoring -o yaml > grafana-dashboards-backup.yaml
```

### Actualizar stack:
```bash
helm repo update
helm upgrade prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring
```

### Limpiar datos antiguos:
Las métricas se eliminan automáticamente después de 30 días según la configuración de retention.
