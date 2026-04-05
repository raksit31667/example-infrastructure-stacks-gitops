data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_count = length(var.private_subnet_cidrs)
  azs      = slice(data.aws_availability_zones.available.names, 0, local.az_count)

  tags = merge(var.tags, {
    Module = "network"
  })
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.tags, {
    Name = "<PROJECT_OR_STACK_NAME>-${var.environment}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, {
    Name = "<PROJECT_OR_STACK_NAME>-${var.environment}-igw"
  })
}

resource "aws_subnet" "private" {
  count = local.az_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(local.tags, {
    Name = "<PROJECT_OR_STACK_NAME>-${var.environment}-private-${local.azs[count.index]}"
    Tier = "private"
    # Required for EKS auto-discovery
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_subnet" "public" {
  count = local.az_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(local.tags, {
    Name = "<PROJECT_OR_STACK_NAME>-${var.environment}-public-${local.azs[count.index]}"
    Tier = "public"
    # Required for EKS auto-discovery
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_eip" "nat" {
  count  = local.az_count
  domain = "vpc"

  tags = merge(local.tags, {
    Name = "<PROJECT_OR_STACK_NAME>-${var.environment}-nat-eip-${count.index}"
  })
}

resource "aws_nat_gateway" "main" {
  count = local.az_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.tags, {
    Name = "<PROJECT_OR_STACK_NAME>-${var.environment}-natgw-${count.index}"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.tags, {
    Name = "<PROJECT_OR_STACK_NAME>-${var.environment}-rt-public"
  })
}

resource "aws_route_table_association" "public" {
  count = local.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = local.az_count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(local.tags, {
    Name = "<PROJECT_OR_STACK_NAME>-${var.environment}-rt-private-${count.index}"
  })
}

resource "aws_route_table_association" "private" {
  count = local.az_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Security group for ElastiCache — allows inbound from within the VPC
resource "aws_security_group" "elasticache" {
  name        = "<PROJECT_OR_STACK_NAME>-${var.environment}-elasticache-sg"
  description = "Security group for ElastiCache clusters"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Valkey/Redis from VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "<PROJECT_OR_STACK_NAME>-${var.environment}-elasticache-sg"
  })
}
