terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca)
  token                  = var.cluster_token
}

provider "helm" {
  kubernetes = {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca)
    token                  = var.cluster_token
  }
}

locals {
  argocd_admin_password = try(data.aws_secretsmanager_secret_version.argocd_admin[0].secret_string, "")
  github_oauth_secret   = try(jsondecode(data.aws_secretsmanager_secret_version.github_oauth[0].secret_string), {})
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = var.argocd_namespace

    labels = {
      "app.kubernetes.io/name"        = "argocd"
      "app.kubernetes.io/managed-by"  = "terraform"
      "app.kubernetes.io/environment" = var.environment
      "app.kubernetes.io/stack"       = var.project_or_stack_name
    }
  }
}

data "aws_secretsmanager_secret" "argocd_admin" {
  count = var.argocd_admin_password_secret_id != "" ? 1 : 0
  name  = var.argocd_admin_password_secret_id
}

data "aws_secretsmanager_secret_version" "argocd_admin" {
  count     = var.argocd_admin_password_secret_id != "" ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.argocd_admin[0].id
}

data "aws_secretsmanager_secret" "github_oauth" {
  count = var.github_oauth_secret_id != "" ? 1 : 0
  name  = var.github_oauth_secret_id
}

data "aws_secretsmanager_secret_version" "github_oauth" {
  count     = var.github_oauth_secret_id != "" ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.github_oauth[0].id
}

resource "helm_release" "this" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = kubernetes_namespace.this.metadata[0].name
  create_namespace = false
  version          = var.argocd_helm_version

  values = [
    templatefile("${path.module}/argocd-values.tftpl", {
      environment           = var.environment
      replicas              = var.argocd_replicas
      dex_enabled           = var.argocd_dex_enabled
      admin_password_secret = local.argocd_admin_password
    })
  ]

  depends_on = [kubernetes_namespace.this]

  atomic  = false
  wait    = true
  timeout = 300
}

resource "kubernetes_cluster_role_binding" "this" {
  metadata {
    name = "argocd-manager"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "argocd-application-controller"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  depends_on = [helm_release.this]
}

resource "kubernetes_secret" "github_deploy_key" {
  count = var.github_oauth_secret_id != "" ? 1 : 0

  metadata {
    name      = "argocd-github-deploy-key"
    namespace = kubernetes_namespace.this.metadata[0].name

    labels = {
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  data = {
    id_rsa = try(local.github_oauth_secret.ssh_private_key, "")
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.this]
}