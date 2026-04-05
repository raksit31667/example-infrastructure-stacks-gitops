identity_token "aws" {
  audience = ["aws.workload.identity"]
}

deployment "infratest" {
  inputs = {
    aws_region     = "<AWS_REGION>"
    role_arn       = "<GITHUB_OIDC_ROLE_ARN>"
    identity_token = identity_token.aws.jwt

    environment          = "infratest"
    cluster_name         = "<PROJECT_OR_STACK_NAME>-infratest"
    vpc_cidr             = "10.0.0.0/16"
    private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
    node_instance_types  = ["m5.large"]
    node_desired_size    = 1
    node_min_size        = 1
    node_max_size        = 3
  }
}

# Publish outputs for consumption by linked microservice stacks
publish_output "vpc_id" {
  value = deployment.infratest.vpc_id
}

publish_output "private_subnet_ids" {
  value = deployment.infratest.private_subnet_ids
}

publish_output "public_subnet_ids" {
  value = deployment.infratest.public_subnet_ids
}

publish_output "elasticache_sg_id" {
  value = deployment.infratest.elasticache_sg_id
}

publish_output "cluster_name" {
  value = deployment.infratest.cluster_name
}

publish_output "cluster_sg_id" {
  value = deployment.infratest.cluster_sg_id
}
