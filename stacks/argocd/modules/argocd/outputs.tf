output "argocd_namespace" {
  description = "Kubernetes namespace where ArgoCD is deployed"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "argocd_release_name" {
  description = "Helm release name for ArgoCD"
  value       = helm_release.this.name
}

output "argocd_release_version" {
  description = "Deployed ArgoCD Helm chart version"
  value       = helm_release.this.version
}

output "argocd_server_service" {
  description = "Kubernetes service name for the ArgoCD server"
  value       = "argocd-server"
}

output "argocd_server_namespace_service" {
  description = "FQDN for the ArgoCD server service"
  value       = "argocd-server.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local"
}