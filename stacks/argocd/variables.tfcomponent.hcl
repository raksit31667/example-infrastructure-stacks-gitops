variable "aws_region" {
  type        = string
  description = "AWS region"
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

variable "cluster_name" {
  type        = string
  description = "EKS cluster name to deploy ArgoCD into"
}

variable "cluster_endpoint" {
  type        = string
  description = "EKS cluster API endpoint"
}

variable "cluster_ca" {
  type        = string
  description = "base64-encoded EKS cluster CA certificate"
}

variable "cluster_token" {
  type        = string
  description = "EKS cluster authentication token"
  sensitive   = true
  ephemeral   = true
}

variable "argocd_namespace" {
  type        = string
  description = "Kubernetes namespace for ArgoCD"
  default     = "argocd"
}

variable "argocd_helm_version" {
  type        = string
  description = "ArgoCD Helm chart version"
  default     = "<ARGOCD_HELM_VERSION>"
}

variable "argocd_admin_password_secret_id" {
  type        = string
  description = "AWS Secrets Manager secret ID containing ArgoCD admin password"
  default     = "argocd-admin-password"
}

variable "github_oauth_secret_id" {
  type        = string
  description = "AWS Secrets Manager secret ID containing GitHub OAuth config (optional)"
  default     = ""
}

variable "project_or_stack_name" {
  type        = string
  description = "Logical stack or project identifier"
  default     = "<PROJECT_OR_STACK_NAME>"
}

variable "argocd_replicas" {
  type        = number
  description = "Number of ArgoCD server replicas for infratest low-cost deployments"
  default     = 1
}

variable "argocd_dex_enabled" {
  type        = bool
  description = "Enable Dex SSO for ArgoCD (set to true for staging/production)"
  default     = false
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
  default = {
    ManagedBy = "Terraform"
    Stack     = "argocd"
  }
}
