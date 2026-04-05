output "nodegroup_name" {
  description = "EKS managed node group name"
  value       = aws_eks_node_group.main.node_group_name
}

output "nodegroup_arn" {
  description = "EKS managed node group ARN"
  value       = aws_eks_node_group.main.arn
}

output "node_role_arn" {
  description = "IAM role ARN used by worker nodes"
  value       = aws_iam_role.node.arn
}
