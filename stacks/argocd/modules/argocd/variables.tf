variable "cluster_endpoint" {
  type        = string
  description = "EKS cluster API endpoint"
}

variable "cluster_ca" {
  type        = string
  description = "Base64-encoded EKS cluster CA certificate"
}

variable "cluster_token" {
  type        = string
  description = "EKS cluster authentication token"
  sensitive   = true
}

variable "argocd_namespace" {
  type        = string
  description = "Kubernetes namespace where ArgoCD is deployed"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "project_or_stack_name" {
  type        = string
  description = "Project or stack identifier used for metadata labels"
}

variable "argocd_admin_password_secret_id" {
  type        = string
  description = "AWS Secrets Manager secret name for the ArgoCD admin password"
  default     = ""
}

variable "github_oauth_secret_id" {
  type        = string
  description = "AWS Secrets Manager secret name containing optional GitHub credentials"
  default     = ""
}

variable "argocd_helm_version" {
  type        = string
  description = "Pinned ArgoCD Helm chart version"
}

variable "argocd_replicas" {
  type        = number
  description = "Replica count for ArgoCD core services"
}

variable "argocd_dex_enabled" {
  type        = bool
  description = "Whether Dex is enabled for SSO"
}