variable "aws_region" {
  description = "Región de AWS donde se desplegará la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Entorno de despliegue (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "cloudedu-services"
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks para subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks para subnets privadas"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "eks_cluster_version" {
  description = "Versión de Kubernetes para EKS"
  type        = string
  default     = "1.28"
}

variable "eks_node_instance_types" {
  description = "Tipos de instancia para nodos de EKS"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_desired_size" {
  description = "Número deseado de nodos"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Número mínimo de nodos"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Número máximo de nodos"
  type        = number
  default     = 4
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks permitidos para SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_http_cidrs" {
  description = "CIDR blocks permitidos para HTTP/HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_nat_gateway" {
  description = "Habilitar NAT Gateway para subnets privadas"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Habilitar VPN Gateway"
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Habilitar DNS hostnames en VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Habilitar DNS support en VPC"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags adicionales para recursos"
  type        = map(string)
  default     = {}
}
