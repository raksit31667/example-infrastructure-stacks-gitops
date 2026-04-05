locals {
  common_tags = {
    Service     = var.service_name
    Environment = var.environment
    ManagedBy   = "Terraform Stacks"
  }
}

component "secret" {
  source = "./modules/secret"

  inputs = {
    aws_region              = var.aws_region
    service_name            = var.service_name
    environment             = var.environment
    secret_string           = var.secret_string
    recovery_window_in_days = var.secret_recovery_window_days
    tags                    = local.common_tags
  }

  providers = {
    aws = provider.aws.this
  }
}

component "elasticache" {
  source = "./modules/elasticache"

  inputs = {
    aws_region                   = var.aws_region
    service_name                 = var.service_name
    environment                  = var.environment
    vpc_id                       = var.vpc_id
    subnets                      = var.elasticache_subnets
    security_group_id            = var.elasticache_security_group_id
    engine                       = var.elasticache_engine
    num_cache_clusters           = var.elasticache_num_cache_clusters
    automatic_failover_enabled   = var.elasticache_automatic_failover_enabled
    service_password_rotation_id = var.elasticache_password_rotation_id
    tags                         = local.common_tags
  }

  providers = {
    aws    = provider.aws.this
  }

  depends_on = [component.secret]
}

component "ecr" {
  source = "./modules/ecr"

  inputs = {
    aws_region           = var.aws_region
    service_name         = var.service_name
    environment          = var.environment
    scan_on_push         = var.ecr_scan_on_push
    image_tag_mutability = var.ecr_image_tag_mutability
    tags                 = local.common_tags
  }

  providers = {
    aws = provider.aws.this
  }
}
