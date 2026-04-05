identity_token "aws" {
  audience = ["aws.workload.identity"]
}

# ── Production ────────────────────────────────────────────────────────────────
# Infrastructure values are sourced from the published contract.
# The microservice-stacks-provision workflow injects these placeholders
# from the S3 contract before plan/apply.

deployment "booking-production" {
  inputs = {
    aws_region     = "<AWS_REGION>"
    role_arn       = "<GITHUB_OIDC_ROLE_ARN>"
    identity_token = identity_token.aws.jwt

    environment  = "production"
    service_name = "booking"

    # Infrastructure contract values — injected by CI from S3
    vpc_id                        = "<VPC_ID_PRODUCTION>"
    elasticache_subnets           = jsondecode("<PRIVATE_SUBNETS_PRODUCTION_JSON>")
    elasticache_security_group_id = "<ELASTICACHE_SG_ID_PRODUCTION>"

    ecr_scan_on_push         = true
    ecr_image_tag_mutability = "IMMUTABLE"

    elasticache_engine                    = "valkey"
    elasticache_num_cache_clusters        = 3
    elasticache_automatic_failover_enabled = true
    elasticache_password_rotation_id      = 0

    # Provide via HCP Terraform variable set or environment secret
    secret_string               = "<BOOKING_PRODUCTION_SECRET_JSON>"
    secret_recovery_window_days = 7
  }
}

# ── Staging ───────────────────────────────────────────────────────────────────

deployment "booking-staging" {
  inputs = {
    aws_region     = "<AWS_REGION>"
    role_arn       = "<GITHUB_OIDC_ROLE_ARN>"
    identity_token = identity_token.aws.jwt

    environment  = "staging"
    service_name = "booking"

    vpc_id                        = "<VPC_ID_STAGING>"
    elasticache_subnets           = jsondecode("<PRIVATE_SUBNETS_STAGING_JSON>")
    elasticache_security_group_id = "<ELASTICACHE_SG_ID_STAGING>"

    ecr_scan_on_push         = true
    ecr_image_tag_mutability = "IMMUTABLE"

    elasticache_engine                    = "valkey"
    elasticache_num_cache_clusters        = 2
    elasticache_automatic_failover_enabled = true
    elasticache_password_rotation_id      = 0

    secret_string               = "<BOOKING_STAGING_SECRET_JSON>"
    secret_recovery_window_days = 7
  }
}

# ── Test ──────────────────────────────────────────────────────────────────────

deployment "booking-test" {
  inputs = {
    aws_region     = "<AWS_REGION>"
    role_arn       = "<GITHUB_OIDC_ROLE_ARN>"
    identity_token = identity_token.aws.jwt

    environment  = "test"
    service_name = "booking"

    vpc_id                        = "<VPC_ID_TEST>"
    elasticache_subnets           = jsondecode("<PRIVATE_SUBNETS_TEST_JSON>")
    elasticache_security_group_id = "<ELASTICACHE_SG_ID_TEST>"

    ecr_scan_on_push         = false
    ecr_image_tag_mutability = "IMMUTABLE"

    elasticache_engine                    = "valkey"
    elasticache_num_cache_clusters        = 1
    elasticache_automatic_failover_enabled = false
    elasticache_password_rotation_id      = 0

    secret_string               = "<BOOKING_TEST_SECRET_JSON>"
    secret_recovery_window_days = 7
  }
}
