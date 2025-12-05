output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas"
  value       = aws_subnet.private[*].id
}

output "eks_cluster_id" {
  description = "ID del cluster EKS"
  value       = aws_eks_cluster.main.id
}

output "eks_cluster_endpoint" {
  description = "Endpoint del cluster EKS"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_name" {
  description = "Nombre del cluster EKS"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_certificate_authority" {
  description = "Certificado de autoridad del cluster EKS"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "eks_cluster_security_group_id" {
  description = "ID del security group del cluster EKS"
  value       = aws_security_group.eks_cluster.id
}

output "eks_node_security_group_id" {
  description = "ID del security group de los nodos EKS"
  value       = aws_security_group.eks_nodes.id
}

output "lb_security_group_id" {
  description = "ID del security group del load balancer"
  value       = aws_security_group.lb.id
}

output "ecr_repository_url" {
  description = "URL del repositorio ECR"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_arn" {
  description = "ARN del repositorio ECR"
  value       = aws_ecr_repository.app.arn
}

output "developers_role_arn" {
  description = "ARN del rol para desarrolladores"
  value       = aws_iam_role.developers.arn
}

output "admins_role_arn" {
  description = "ARN del rol para administradores"
  value       = aws_iam_role.admins.arn
}

output "cicd_role_arn" {
  description = "ARN del rol para CI/CD"
  value       = aws_iam_role.cicd.arn
}

output "github_actions_user_name" {
  description = "Nombre del usuario IAM para GitHub Actions"
  value       = aws_iam_user.github_actions.name
}

output "github_actions_access_key_id" {
  description = "Access Key ID para GitHub Actions"
  value       = aws_iam_access_key.github_actions.id
  sensitive   = true
}

output "github_actions_secret_access_key" {
  description = "Secret Access Key para GitHub Actions"
  value       = aws_iam_access_key.github_actions.secret
  sensitive   = true
}

output "configure_kubectl" {
  description = "Comando para configurar kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "region" {
  description = "Región de AWS"
  value       = var.aws_region
}
