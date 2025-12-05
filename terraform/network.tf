# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  tags = merge(
    {
      Name = "${var.project_name}-vpc"
      "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
    },
    var.tags
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    {
      Name = "${var.project_name}-igw"
    },
    var.tags
  )
}

# Subnets Públicas
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(
    {
      Name = "${var.project_name}-public-subnet-${count.index + 1}"
      "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
      "kubernetes.io/role/elb" = "1"
    },
    var.tags
  )
}

# Subnets Privadas
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = merge(
    {
      Name = "${var.project_name}-private-subnet-${count.index + 1}"
      "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
      "kubernetes.io/role/internal-elb" = "1"
    },
    var.tags
  )
}

# Elastic IP para NAT Gateway
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"
  
  tags = merge(
    {
      Name = "${var.project_name}-nat-eip"
    },
    var.tags
  )
  
  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  
  tags = merge(
    {
      Name = "${var.project_name}-nat-gateway"
    },
    var.tags
  )
  
  depends_on = [aws_internet_gateway.main]
}

# Route Table Pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(
    {
      Name = "${var.project_name}-public-rt"
    },
    var.tags
  )
}

# Route Table Privada
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }
  
  tags = merge(
    {
      Name = "${var.project_name}-private-rt"
    },
    var.tags
  )
}

# Asociaciones Route Table Públicas
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Asociaciones Route Table Privadas
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Group para EKS Cluster
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.project_name}-eks-cluster-sg-"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.main.id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(
    {
      Name = "${var.project_name}-eks-cluster-sg"
    },
    var.tags
  )
}

# Security Group para nodos de EKS
resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.project_name}-eks-nodes-sg-"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description = "Allow nodes to communicate with each other"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }
  
  ingress {
    description     = "Allow pods to communicate with cluster API"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(
    {
      Name = "${var.project_name}-eks-nodes-sg"
    },
    var.tags
  )
}

# Security Group para Load Balancer
resource "aws_security_group" "lb" {
  name_prefix = "${var.project_name}-lb-sg-"
  description = "Security group for load balancer"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidrs
  }
  
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidrs
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(
    {
      Name = "${var.project_name}-lb-sg"
    },
    var.tags
  )
}
