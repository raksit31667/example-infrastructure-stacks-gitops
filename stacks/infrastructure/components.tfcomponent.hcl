locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform Stacks"
    Owner       = "<OWNER_TEAM>"
  }
}

component "network" {
  source = "./modules/network"

  inputs = {
    aws_region           = var.aws_region
    environment          = var.environment
    vpc_cidr             = var.vpc_cidr
    private_subnet_cidrs = var.private_subnet_cidrs
    public_subnet_cidrs  = var.public_subnet_cidrs
    tags                 = local.common_tags
  }

  providers = {
    aws = provider.aws.this
  }
}

component "kubernetes_controlplane" {
  source = "./modules/kubernetes-controlplane"

  inputs = {
    aws_region         = var.aws_region
    environment        = var.environment
    cluster_name       = var.cluster_name
    vpc_id             = component.network.vpc_id
    private_subnet_ids = component.network.private_subnet_ids
    tags               = local.common_tags
  }

  providers = {
    aws = provider.aws.this
  }
}

component "nodegroup" {
  source = "./modules/nodegroup"

  inputs = {
    aws_region          = var.aws_region
    environment         = var.environment
    cluster_name        = component.kubernetes_controlplane.cluster_name
    cluster_endpoint    = component.kubernetes_controlplane.cluster_endpoint
    vpc_id              = component.network.vpc_id
    private_subnet_ids  = component.network.private_subnet_ids
    node_instance_types = var.node_instance_types
    node_desired_size   = var.node_desired_size
    node_min_size       = var.node_min_size
    node_max_size       = var.node_max_size
    tags                = local.common_tags
  }

  providers = {
    aws = provider.aws.this
  }
}
