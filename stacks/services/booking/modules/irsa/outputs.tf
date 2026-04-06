output "role_arn" {
  description = "IRSA IAM role ARN"
  value       = aws_iam_role.main.arn
}

output "role_name" {
  description = "IRSA IAM role name"
  value       = aws_iam_role.main.name
}
