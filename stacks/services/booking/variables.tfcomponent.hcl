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
  description = "Deployment environment: production, staging, test"
}

variable "service_name" {
  type        = string
  description = "Service name (used as a prefix for all resources)"
  default     = "booking"
}

# ── Infrastructure outputs (passed from infrastructure contract) ──────────────

variable "vpc_id" {
  type        = string
  description = "VPC ID from the infrastructure stack contract"
}

variable "elasticache_subnets" {
  type        = list(string)
  description = "Private subnet IDs for ElastiCache from the infrastructure stack contract"
}

variable "elasticache_security_group_id" {
  type        = string
  description = "Security group ID for ElastiCache from the infrastructure stack contract"
}

# ── ECR ───────────────────────────────────────────────────────────────────────

variable "ecr_scan_on_push" {
  type        = bool
  description = "Enable ECR image scanning on push"
  default     = true
}

variable "ecr_image_tag_mutability" {
  type        = string
  description = "ECR image tag mutability (MUTABLE or IMMUTABLE)"
  default     = "IMMUTABLE"
}

# ── ElastiCache ───────────────────────────────────────────────────────────────

variable "elasticache_engine" {
  type        = string
  description = "ElastiCache engine (valkey or redis)"
  default     = "valkey"
}

variable "elasticache_num_cache_clusters" {
  type        = number
  description = "Number of cache clusters in the replication group"
  default     = 1
}

variable "elasticache_automatic_failover_enabled" {
  type        = bool
  description = "Enable automatic failover for ElastiCache"
  default     = false
}

variable "elasticache_password_rotation_id" {
  type        = number
  description = "Increment to force service user password rotation"
  default     = 0
}

# ── Secrets Manager ───────────────────────────────────────────────────────────

variable "secret_string" {
  type        = string
  description = "Secret value (JSON string) for the service"
  sensitive   = true
  ephemeral   = true
}

variable "secret_recovery_window_days" {
  type        = number
  description = "Recovery window for secret deletion (days)"
  default     = 7
}

# ── IRSA ──────────────────────────────────────────────────────────────────────

variable "oidc_provider_arn" {
  type        = string
  description = "EKS OIDC provider ARN (from infrastructure stack contract)"
}

variable "oidc_provider_url" {
  type        = string
  description = "EKS OIDC provider URL without https:// (from infrastructure stack contract)"
}

variable "k8s_namespace" {
  type        = string
  description = "Kubernetes namespace where the service account lives"
  default     = "booking"
}

variable "k8s_service_account_name" {
  type        = string
  description = "Kubernetes service account name to bind to the IRSA role"
  default     = "booking"
}
