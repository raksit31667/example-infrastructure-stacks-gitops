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

variable "secret_string" {
  description = "Secret value (JSON string or key:value pairs)"
  type        = string
  sensitive   = true
}

variable "recovery_window_in_days" {
  description = "Recovery window for secret deletion (days)"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
