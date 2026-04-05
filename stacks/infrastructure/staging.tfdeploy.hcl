identity_token "aws" {
  audience = ["aws.workload.identity"]
}

deployment "staging" {
  inputs = {
    aws_region     = "<AWS_REGION>"
    role_arn       = "<GITHUB_OIDC_ROLE_ARN>"
    identity_token = identity_token.aws.jwt

    environment          = "staging"
    cluster_name         = "<PROJECT_OR_STACK_NAME>-staging"
    vpc_cidr             = "10.1.0.0/16"
    private_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
    public_subnet_cidrs  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
    node_instance_types  = ["m5.large"]
    node_desired_size    = 2
    node_min_size        = 1
    node_max_size        = 5
  }
}

publish_output "vpc_id" {
  value = deployment.staging.vpc_id
}

publish_output "private_subnet_ids" {
  value = deployment.staging.private_subnet_ids
}

publish_output "public_subnet_ids" {
  value = deployment.staging.public_subnet_ids
}

publish_output "elasticache_sg_id" {
  value = deployment.staging.elasticache_sg_id
}

publish_output "cluster_name" {
  value = deployment.staging.cluster_name
}

publish_output "cluster_sg_id" {
  value = deployment.staging.cluster_sg_id
}
