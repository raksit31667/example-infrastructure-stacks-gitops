variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "service_name" {
  description = "Microservice name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN (from infrastructure stack contract)"
  type        = string
}

variable "oidc_provider_url" {
  description = "EKS OIDC provider URL without https:// (from infrastructure stack contract)"
  type        = string
}

variable "k8s_namespace" {
  description = "Kubernetes namespace where the service account lives"
  type        = string
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name to bind to the IRSA role"
  type        = string
}

variable "elasticache_arn" {
  description = "ElastiCache serverless cache ARN"
  type        = string
}

variable "elasticache_user_arn" {
  description = "ElastiCache service user ARN"
  type        = string
}

variable "secret_arn" {
  description = "Secrets Manager secret ARN"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
