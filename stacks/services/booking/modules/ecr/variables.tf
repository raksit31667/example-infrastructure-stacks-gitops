variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "service_name" {
  description = "Microservice name (used as the ECR repository name)"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "encryption_type" {
  description = "Encryption type for the ECR repository (AES256 or KMS)"
  type        = string
  default     = "KMS"
}

variable "image_tag_mutability" {
  description = "Image tag mutability (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "IMMUTABLE"
}

variable "scan_on_push" {
  description = "Enable ECR image scanning on push"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
