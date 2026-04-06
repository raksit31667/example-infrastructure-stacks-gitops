# ── Infrastructure Outputs ─────────────────────────────────────────────────
# Expose infrastructure stack outputs for external consumption and contract generation

# Network outputs
output "vpc_id" {
  type        = string
  description = "VPC ID for the environment"
  value       = component.network.vpc_id
}

output "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  value       = component.network.vpc_cidr
}

output "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs"
  value       = component.network.private_subnet_ids
}

output "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs"
  value       = component.network.public_subnet_ids
}

output "elasticache_sg_id" {
  type        = string
  description = "Security group ID for ElastiCache"
  value       = component.network.elasticache_sg_id
}

# Kubernetes cluster outputs
output "cluster_name" {
  type        = string
  description = "EKS cluster name"
  value       = component.kubernetes_controlplane.cluster_name
}

output "cluster_endpoint" {
  type        = string
  description = "EKS cluster API server endpoint URL"
  value       = component.kubernetes_controlplane.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  type        = string
  description = "Base64-encoded certificate authority data for the cluster"
  value       = component.kubernetes_controlplane.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_sg_id" {
  type        = string
  description = "EKS cluster security group ID"
  value       = component.kubernetes_controlplane.cluster_sg_id
}

output "cluster_oidc_issuer_url" {
  type        = string
  description = "OIDC issuer URL for IRSA (IAM Roles for Service Accounts)"
  value       = component.kubernetes_controlplane.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  type        = string
  description = "ARN of the OIDC provider for IRSA"
  value       = component.kubernetes_controlplane.oidc_provider_arn
}

# Node group outputs
output "nodegroup_name" {
  type        = string
  description = "EKS managed node group name"
  value       = component.nodegroup.nodegroup_name
}

output "node_role_arn" {
  type        = string
  description = "IAM role ARN used by worker nodes"
  value       = component.nodegroup.node_role_arn
}
