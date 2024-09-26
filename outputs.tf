# outputs.tf

output "aws_eks_cluster" {
  description = "EKS cluster attributes."
  value       = aws_eks_cluster.self
}

output "aws_iam_openid_connect_provider" {
  description = "Open ID Connect provider attributes"
  value       = aws_iam_openid_connect_provider.self
}

output "aws_iam_roles" {
  description = "Roles attributes."
  value = {
    eks_fargate = aws_iam_role.eks_fargate
    eks_node    = aws_iam_role.eks_node
  }
}
