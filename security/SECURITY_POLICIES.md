# Políticas de Seguridad para CloudEdu Services

## 1. Pod Security Standards

### Aplicar Pod Security Standards al namespace
```bash
kubectl label namespace cloudedu-services \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

## 2. Network Policies

Las Network Policies están definidas en `networkpolicy.yaml` y proporcionan:
- Aislamiento de red a nivel de pod
- Control de tráfico ingress y egress
- Restricción de comunicación entre namespaces

## 3. RBAC (Role-Based Access Control)

### Roles Definidos:

#### ServiceAccount (cloudedu-sa)
- Asociado a los pods de la aplicación
- Permisos mínimos necesarios para operación

#### Developer Role
- Acceso de solo lectura a recursos del namespace
- Puede ver logs pero no modificar recursos
- Ideal para desarrolladores y QA

#### Admin Role
- Acceso completo a recursos del cluster
- Puede crear, modificar y eliminar recursos
- Restringido a personal autorizado

### Grupos de AWS IAM mapeados a K8s:
- `cloudedu-admins` → Administradores del sistema
- `cloudedu-developers` → Desarrolladores con acceso limitado

## 4. Políticas de Recursos

### ResourceQuota
- Límite total de CPU: 8 cores
- Límite total de memoria: 16Gi
- Máximo de 20 pods
- Máximo de 5 PVCs

### LimitRange
- Límites por contenedor
- Límites por pod
- Requests por defecto configurados

## 5. Pod Disruption Budget

- Garantiza que al menos 1 pod esté disponible durante mantenimiento
- Previene interrupciones completas del servicio

## 6. Security Context

Los pods ejecutan con:
- Usuario no privilegiado (UID 1000)
- Sin escalación de privilegios
- Capabilities mínimas
- Sistema de archivos de solo lectura (excepto /app/data)

## 7. Secrets Management

### Mejores Prácticas:

1. **No commitear secrets en Git**
   ```bash
   # Crear secrets desde archivos
   kubectl create secret generic cloudedu-secrets \
     --from-file=SECRET_KEY=./secret-key.txt \
     -n cloudedu-services
   ```

2. **Usar AWS Secrets Manager** (recomendado en producción)
   ```bash
   # Instalar External Secrets Operator
   helm repo add external-secrets https://charts.external-secrets.io
   helm install external-secrets \
     external-secrets/external-secrets \
     -n external-secrets-system \
     --create-namespace
   ```

3. **Rotar secrets regularmente**
   ```bash
   # Script de rotación automática
   kubectl delete secret cloudedu-secrets -n cloudedu-services
   kubectl create secret generic cloudedu-secrets \
     --from-literal=SECRET_KEY=$(openssl rand -hex 32) \
     -n cloudedu-services
   
   # Reiniciar pods para aplicar nuevos secrets
   kubectl rollout restart deployment/cloudedu-app -n cloudedu-services
   ```

## 8. Image Security

### Escaneo de Vulnerabilidades:
- ECR escanea automáticamente las imágenes
- Revisar resultados en AWS Console

```bash
# Ver resultados de escaneo
aws ecr describe-image-scan-findings \
  --repository-name cloudedu-services-app \
  --image-id imageTag=latest
```

### Firma de Imágenes:
```bash
# Usar Docker Content Trust
export DOCKER_CONTENT_TRUST=1
docker push REGISTRY/cloudedu-services-app:latest
```

## 9. Auditoría y Logging

### Habilitar Audit Logs en EKS:
```bash
# Ya configurado en terraform/eks.tf
# enabled_cluster_log_types = ["api", "audit", "authenticator"]
```

### Ver logs de auditoría:
```bash
# En CloudWatch Logs
aws logs tail /aws/eks/cloudedu-services-eks/cluster --follow
```

## 10. Checklist de Seguridad

- [ ] Secrets no están en el código fuente
- [ ] Imágenes escaneadas por vulnerabilidades
- [ ] RBAC configurado correctamente
- [ ] Network Policies aplicadas
- [ ] Resource Limits definidos
- [ ] Pod Security Standards aplicados
- [ ] Audit logging habilitado
- [ ] Backup y disaster recovery configurado
- [ ] Secrets rotados regularmente
- [ ] Acceso SSH deshabilitado en nodos
- [ ] Encryption at rest habilitado (EBS)
- [ ] Encryption in transit habilitado (TLS)

## 11. Comandos Útiles de Seguridad

```bash
# Verificar permisos de ServiceAccount
kubectl auth can-i --list --as=system:serviceaccount:cloudedu-services:cloudedu-sa

# Ver pods que no cumplen Pod Security Standards
kubectl get pods -n cloudedu-services -o json | \
  jq '.items[] | select(.spec.securityContext.runAsNonRoot != true)'

# Auditar Network Policies
kubectl get networkpolicies -n cloudedu-services

# Ver recursos consumidos
kubectl top pods -n cloudedu-services
kubectl top nodes

# Verificar configuración de RBAC
kubectl get rolebindings,clusterrolebindings -n cloudedu-services

# Ver eventos de seguridad
kubectl get events -n cloudedu-services --field-selector type=Warning
```

## 12. Monitoreo de Seguridad

### Configurar alertas para:
- Intentos de acceso no autorizado
- Uso excesivo de recursos
- Pods en estado de error
- Cambios en configuración de seguridad
- Vulnerabilidades detectadas en imágenes

### Herramientas recomendadas:
- **Falco**: Runtime security monitoring
- **OPA/Gatekeeper**: Policy enforcement
- **Trivy**: Vulnerability scanning
- **KubeBench**: CIS Kubernetes Benchmark
