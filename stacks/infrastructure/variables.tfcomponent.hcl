variable "aws_region" {
  type        = string
  description = "AWS region for deployments"
  default     = "<AWS_REGION>"
}

variable "identity_token" {
  type        = string
  description = "OIDC identity token for AWS authentication"
  ephemeral   = true
}

variable "role_arn" {
  type        = string
  description = "IAM role ARN for assume role with web identity"
}

variable "environment" {
  type        = string
  description = "Deployment environment: infratest, staging, production"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets (one per AZ)"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets (one per AZ)"
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "node_instance_types" {
  type        = list(string)
  description = "EC2 instance types for EKS managed node group"
  default     = ["m5.large"]
}

variable "node_desired_size" {
  type        = number
  description = "Desired number of worker nodes"
  default     = 2
}

variable "node_min_size" {
  type        = number
  description = "Minimum number of worker nodes"
  default     = 1
}

variable "node_max_size" {
  type        = number
  description = "Maximum number of worker nodes"
  default     = 5
}
