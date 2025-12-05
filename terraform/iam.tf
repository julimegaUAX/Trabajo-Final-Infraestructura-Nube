# IAM Role para desarrolladores
resource "aws_iam_role" "developers" {
  name = "${var.project_name}-developers-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
    }]
  })
  
  tags = merge(
    {
      Name = "${var.project_name}-developers-role"
    },
    var.tags
  )
}

# Política para desarrolladores (solo lectura del cluster)
resource "aws_iam_policy" "developers_eks_readonly" {
  name        = "${var.project_name}-developers-eks-readonly"
  description = "Read-only access to EKS cluster"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "developers_eks_readonly" {
  policy_arn = aws_iam_policy.developers_eks_readonly.arn
  role       = aws_iam_role.developers.name
}

# IAM Role para administradores
resource "aws_iam_role" "admins" {
  name = "${var.project_name}-admins-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
    }]
  })
  
  tags = merge(
    {
      Name = "${var.project_name}-admins-role"
    },
    var.tags
  )
}

# Política para administradores (acceso completo al cluster)
resource "aws_iam_policy" "admins_eks_full" {
  name        = "${var.project_name}-admins-eks-full"
  description = "Full access to EKS cluster management"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "eks.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "admins_eks_full" {
  policy_arn = aws_iam_policy.admins_eks_full.arn
  role       = aws_iam_role.admins.name
}

# IAM Role para CI/CD
resource "aws_iam_role" "cicd" {
  name = "${var.project_name}-cicd-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
    }]
  })
  
  tags = merge(
    {
      Name = "${var.project_name}-cicd-role"
    },
    var.tags
  )
}

# Política para CI/CD (despliegue de aplicaciones)
resource "aws_iam_policy" "cicd_deploy" {
  name        = "${var.project_name}-cicd-deploy"
  description = "Policy for CI/CD deployments to EKS"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cicd_deploy" {
  policy_arn = aws_iam_policy.cicd_deploy.arn
  role       = aws_iam_role.cicd.name
}

# Data source para obtener el ID de la cuenta
data "aws_caller_identity" "current" {}

# IAM User para CI/CD (GitHub Actions)
resource "aws_iam_user" "github_actions" {
  name = "${var.project_name}-github-actions"
  path = "/system/"
  
  tags = merge(
    {
      Name        = "${var.project_name}-github-actions"
      Description = "User for GitHub Actions CI/CD"
    },
    var.tags
  )
}

# Política inline para el usuario de GitHub Actions
resource "aws_iam_user_policy" "github_actions_policy" {
  name = "${var.project_name}-github-actions-policy"
  user = aws_iam_user.github_actions.name
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = aws_eks_cluster.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = aws_ecr_repository.app.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = aws_iam_role.cicd.arn
      }
    ]
  })
}

# Access keys para el usuario de GitHub Actions
resource "aws_iam_access_key" "github_actions" {
  user = aws_iam_user.github_actions.name
}

# ECR Repository para la aplicación
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-app"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  encryption_configuration {
    encryption_type = "AES256"
  }
  
  tags = merge(
    {
      Name = "${var.project_name}-app"
    },
    var.tags
  )
}

# Lifecycle policy para ECR
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
