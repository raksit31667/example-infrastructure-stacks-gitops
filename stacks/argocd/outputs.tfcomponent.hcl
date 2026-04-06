output "argocd_namespace" {
  type        = string
  description = "Kubernetes namespace where ArgoCD is deployed"
  value       = component.argocd.argocd_namespace
}

output "argocd_release_name" {
  type        = string
  description = "Helm release name for ArgoCD"
  value       = component.argocd.argocd_release_name
}

output "argocd_release_version" {
  type        = string
  description = "Deployed ArgoCD Helm chart version"
  value       = component.argocd.argocd_release_version
}

output "argocd_server_service" {
  type        = string
  description = "Kubernetes service name for ArgoCD server"
  value       = component.argocd.argocd_server_service
}

output "argocd_server_namespace_service" {
  type        = string
  description = "FQDN for ArgoCD server service in cluster"
  value       = component.argocd.argocd_server_namespace_service
}

output "cluster_name" {
  type        = string
  description = "EKS cluster name where ArgoCD is deployed"
  value       = var.cluster_name
}

output "environment" {
  type        = string
  description = "Deployment environment"
  value       = var.environment
}

output "next_steps" {
  type        = string
  description = "Steps to access and configure ArgoCD"
  value = <<-EOT
    1. Port-forward to ArgoCD server (from kubectl context):
     kubectl -n ${component.argocd.argocd_namespace} port-forward svc/${component.argocd.argocd_server_service} 8080:443

    2. Access UI at: https://localhost:8080
       - Username: admin
       - Password: Retrieved from AWS Secrets Manager

    3. Add repository (via argocd CLI):
       argocd repo add <REPOSITORY_GIT_URL> --upsert --ssh-private-key-path <PATH_TO_KEY>

    4. Create ApplicationSet for microservices later

    5. (Optional) Set up GitHub SSO via Dex configuration
  EOT
}