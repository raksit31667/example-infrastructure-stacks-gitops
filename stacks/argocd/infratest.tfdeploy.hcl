identity_token "aws" {
  audience = ["aws.workload.identity"]
}

deployment "infratest" {
  inputs = {
    aws_region     = "<AWS_REGION>"
    role_arn       = "<GITHUB_OIDC_ROLE_ARN>"
    identity_token = identity_token.aws.jwt

    environment               = "infratest"
    cluster_name              = "<PROJECT_OR_STACK_NAME>-infratest-eks"
    cluster_endpoint          = "<CLUSTER_ENDPOINT_PLACEHOLDER>"
    cluster_ca                = "<CLUSTER_CA_CERT_PLACEHOLDER>"
    cluster_token             = "<CLUSTER_TOKEN_PLACEHOLDER>"
    argocd_namespace          = "argocd"
    argocd_helm_version       = "5.46.8"
    project_or_stack_name     = "<PROJECT_OR_STACK_NAME>"
    argocd_replicas           = 1
    argocd_dex_enabled        = false
    argocd_admin_password_secret_id = "argocd-admin-password-infratest"
    github_oauth_secret_id    = ""

    common_tags = {
      ManagedBy   = "Terraform"
      Stack       = "argocd"
      Environment = "infratest"
    }
  }
}

# Publish outputs for consumption by other stacks
publish_output "argocd_namespace" {
  value = deployment.infratest.argocd_namespace
}

publish_output "argocd_server_service" {
  value = deployment.infratest.argocd_server_service
}

publish_output "argocd_server_namespace_service" {
  value = deployment.infratest.argocd_server_namespace_service
}
