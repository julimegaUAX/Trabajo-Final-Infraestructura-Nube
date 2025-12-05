# CloudEdu Services - Proyecto Cloud-Native

## 📋 Descripción del Proyecto

Migración de una aplicación web interna de CloudEdu Services a una arquitectura cloud-native utilizando contenedores Docker, Kubernetes e Infrastructure as Code (IaC).

## 🏗️ Arquitectura

Este proyecto implementa una solución completa que incluye:

- **Aplicación Web**: Sistema de gestión educativa construido con Node.js y Express
- **Contenedorización**: Docker con imagen personalizada
- **Orquestación**: Kubernetes para gestión de contenedores
- **IaC**: Terraform para provisión de infraestructura
- **Persistencia**: PersistentVolumeClaims para datos
- **Seguridad**: IAM roles y políticas de acceso
- **CI/CD**: GitHub Actions para despliegue automatizado
- **Monitorización**: Prometheus y Grafana (opcional)

## 📁 Estructura del Proyecto

```
.
├── app/                    # Código fuente de la aplicación
│   ├── src/               # Código Node.js
│   └── public/            # Recursos estáticos
├── docker/                # Configuración Docker
│   └── Dockerfile         # Imagen personalizada
├── kubernetes/            # Manifiestos K8s
│   ├── deployment.yaml    # Deployment
│   ├── service.yaml       # Service
│   ├── pvc.yaml          # Persistent Volume Claims
│   ├── ingress.yaml      # Ingress Controller
│   └── rbac.yaml         # Roles y permisos
├── terraform/             # Infrastructure as Code
│   ├── main.tf           # Configuración principal
│   ├── variables.tf      # Variables
│   └── outputs.tf        # Outputs
├── .github/              # CI/CD
│   └── workflows/        # GitHub Actions
├── scripts/              # Scripts de despliegue
├── docs/                 # Documentación
│   ├── arquitectura.md   # Diagrama de arquitectura
│   ├── guia-despliegue.md # Guía de despliegue
│   └── iam-security.md   # Seguridad y IAM
└── README.md             # Este archivo
```

## 🚀 Inicio Rápido

### Requisitos Previos

- Docker Desktop
- kubectl
- Terraform
- Minikube o acceso a cluster Kubernetes
- Git

### Despliegue Local

```bash
# 1. Clonar el repositorio
git clone <repository-url>
cd Trabajo-Final-Infraestructura-Nube

# 2. Construir la imagen Docker
docker build -t cloudedu-app:latest -f docker/Dockerfile .

# 3. Iniciar Minikube
minikube start

# 4. Aplicar manifiestos Kubernetes
kubectl apply -f kubernetes/

# 5. Verificar el despliegue
kubectl get pods
kubectl get svc
```

### Despliegue con Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## 🔒 Seguridad e IAM

El proyecto implementa:
- Roles RBAC en Kubernetes
- Service Accounts con permisos limitados
- Network Policies
- Secrets management
- IAM roles en cloud provider

Ver más detalles en [docs/iam-security.md](docs/iam-security.md)

## 📊 Monitorización

Prometheus y Grafana configurados para:
- Métricas de aplicación
- Estado del cluster
- Uso de recursos
- Alertas

## 🔄 CI/CD

Pipeline automatizado con GitHub Actions:
- Build de imagen Docker
- Tests
- Push a registry
- Despliegue a Kubernetes

## 👥 Equipo

- CloudEdu DevOps Team

## 📝 Licencia

Este proyecto es parte de la práctica final de Infraestructura en la Nube - UAX

## 📚 Documentación Adicional

- [Guía de Despliegue Completa](docs/guia-despliegue.md)
- [Arquitectura del Sistema](docs/arquitectura.md)
- [Seguridad y Control de Acceso](docs/iam-security.md)
