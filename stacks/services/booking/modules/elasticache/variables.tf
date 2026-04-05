variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "service_name" {
  description = "Microservice name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the ElastiCache subnet group"
  type        = string
}

variable "subnets" {
  description = "Subnet IDs for the ElastiCache cluster"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID to attach to the ElastiCache cluster"
  type        = string
}

variable "engine" {
  description = "Cache engine (valkey or redis)"
  type        = string
  default     = "valkey"
}

variable "num_cache_clusters" {
  description = "Number of cache clusters in the replication group"
  type        = number
  default     = 1
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover (requires num_cache_clusters >= 2)"
  type        = bool
  default     = false
}

variable "engine_version" {
  description = "Engine version (leave null to use the latest)"
  type        = string
  default     = null
}

variable "service_password_rotation_id" {
  description = "Increment to trigger service user password rotation"
  type        = number
  default     = 0
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
