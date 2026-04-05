identity_token "aws" {
  audience = ["aws.workload.identity"]
}

deployment "production" {
  inputs = {
    aws_region     = "<AWS_REGION>"
    role_arn       = "<GITHUB_OIDC_ROLE_ARN>"
    identity_token = identity_token.aws.jwt

    environment          = "production"
    cluster_name         = "<PROJECT_OR_STACK_NAME>-production"
    vpc_cidr             = "10.2.0.0/16"
    private_subnet_cidrs = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
    public_subnet_cidrs  = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24"]
    node_instance_types  = ["m5.xlarge"]
    node_desired_size    = 3
    node_min_size        = 2
    node_max_size        = 10
  }
}

publish_output "vpc_id" {
  value = deployment.production.vpc_id
}

publish_output "private_subnet_ids" {
  value = deployment.production.private_subnet_ids
}

publish_output "public_subnet_ids" {
  value = deployment.production.public_subnet_ids
}

publish_output "elasticache_sg_id" {
  value = deployment.production.elasticache_sg_id
}

publish_output "cluster_name" {
  value = deployment.production.cluster_name
}

publish_output "cluster_sg_id" {
  value = deployment.production.cluster_sg_id
}
