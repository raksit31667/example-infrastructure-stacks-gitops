component "argocd" {
  source = "./modules/argocd"

  inputs = {
    cluster_endpoint                = var.cluster_endpoint
    cluster_ca                      = var.cluster_ca
    cluster_token                   = var.cluster_token
    argocd_namespace                = var.argocd_namespace
    environment                     = var.environment
    project_or_stack_name           = var.project_or_stack_name
    argocd_admin_password_secret_id = var.argocd_admin_password_secret_id
    github_oauth_secret_id          = var.github_oauth_secret_id
    argocd_helm_version             = var.argocd_helm_version
    argocd_replicas                 = var.argocd_replicas
    argocd_dex_enabled              = var.argocd_dex_enabled
  }

  providers = {
    aws = provider.aws.this
  }
}
