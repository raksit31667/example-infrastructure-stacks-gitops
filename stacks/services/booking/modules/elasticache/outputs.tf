output "primary_endpoint_address" {
  description = "ElastiCache primary endpoint address"
  value       = aws_elasticache_serverless_cache.main.endpoint[0].address
}

output "reader_endpoint_address" {
  description = "ElastiCache reader endpoint address"
  value       = try(aws_elasticache_serverless_cache.main.reader_endpoint[0].address, null)
}

output "port" {
  description = "ElastiCache port"
  value       = aws_elasticache_serverless_cache.main.endpoint[0].port
}

output "engine" {
  description = "ElastiCache engine type"
  value       = var.engine
}

output "service_user_id" {
  description = "ElastiCache service user ID"
  value       = aws_elasticache_user.service.user_id
}

output "service_password" {
  description = "ElastiCache service user password"
  value       = random_password.service_password.result
  sensitive   = true
}

output "connection_string" {
  description = "ElastiCache connection string (endpoint:port)"
  value       = "${aws_elasticache_serverless_cache.main.endpoint[0].address}:${aws_elasticache_serverless_cache.main.endpoint[0].port}"
}

output "cache_arn" {
  description = "ElastiCache serverless cache ARN"
  value       = aws_elasticache_serverless_cache.main.arn
}

output "service_user_arn" {
  description = "ElastiCache service user ARN"
  value       = aws_elasticache_user.service.arn
}
