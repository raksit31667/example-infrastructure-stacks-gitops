output "ecr_repository_url" {
  type        = string
  description = "ECR repository URL"
  value       = component.ecr.repository_url
}

output "ecr_repository_arn" {
  type        = string
  description = "ECR repository ARN"
  value       = component.ecr.repository_arn
}

output "ecr_registry_id" {
  type        = string
  description = "AWS account ID (ECR registry ID)"
  value       = component.ecr.registry_id
}

output "elasticache_endpoint" {
  type        = string
  description = "ElastiCache primary endpoint address"
  value       = component.elasticache.primary_endpoint_address
}

output "elasticache_reader_endpoint" {
  type        = string
  description = "ElastiCache reader endpoint address"
  value       = component.elasticache.reader_endpoint_address
}

output "elasticache_port" {
  type        = number
  description = "ElastiCache port"
  value       = component.elasticache.port
}

output "elasticache_connection_string" {
  type        = string
  description = "ElastiCache connection string (endpoint:port)"
  value       = component.elasticache.connection_string
}

output "elasticache_service_user_id" {
  type        = string
  description = "ElastiCache service user ID"
  value       = component.elasticache.service_user_id
}

output "secret_arn" {
  type        = string
  description = "Secrets Manager secret ARN"
  value       = component.secret.secret_arn
}

output "secret_name" {
  type        = string
  description = "Secrets Manager secret name"
  value       = component.secret.secret_name
}

output "irsa_role_arn" {
  type        = string
  description = "IRSA IAM role ARN for the booking service"
  value       = component.irsa.role_arn
}

output "irsa_role_name" {
  type        = string
  description = "IRSA IAM role name for the booking service"
  value       = component.irsa.role_name
}
