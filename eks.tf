# eks.tf

resource "aws_eks_cluster" "self" {
  #checkov:skip=CKV_AWS_37:Ensure Amazon EKS control plane logging is enabled for all log types
  #checkov:skip=CKV_AWS_38:Ensure Amazon EKS public endpoint not accessible to 0.0.0.0/0
  #checkov:skip=CKV_AWS_39:Ensure Amazon EKS public endpoint disabled
  #checkov:skip=CKV_AWS_58:Ensure EKS Cluster has Secrets Encryption Enabled
  #checkov:skip=CKV_AWS_339:Ensure EKS clusters run on a supported Kubernetes version
  name     = local.name_prefix
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids = var.subnet_ids
    # endpoint_public_access  = false
    endpoint_private_access = true
    # security_group_ids      = [ aws_security_group.self.id ]
  }

  # access_config {
  #   authentication_mode = "API"
  #   bootstrap_cluster_creator_admin_permissions = true
  # }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]
}

resource "aws_eks_addon" "self" {
  for_each                 = local.eks_addons
  addon_name               = each.key
  addon_version            = data.aws_eks_addon_version.self[each.key].version
  cluster_name             = aws_eks_cluster.self.name
  service_account_role_arn = try(aws_iam_role.eks_addons[each.key].arn, "")
  depends_on               = [aws_eks_fargate_profile.self, aws_eks_node_group.self]
}

resource "aws_eks_fargate_profile" "self" {
  for_each               = local.eks_farget_profiles
  fargate_profile_name   = each.key
  cluster_name           = aws_eks_cluster.self.name
  pod_execution_role_arn = aws_iam_role.eks_fargate[0].arn
  subnet_ids             = var.subnet_ids

  selector {
    namespace = try(each.value.namespace, null)
    labels    = try(each.value.labels, null)
  }
}

resource "aws_eks_node_group" "self" {
  for_each        = local.eks_node_groups
  cluster_name    = aws_eks_cluster.self.name
  subnet_ids      = var.subnet_ids
  node_role_arn   = aws_iam_role.eks_node[0].arn
  node_group_name = each.key
  ami_type        = each.value.ami_type
  capacity_type   = each.value.capacity_type

  scaling_config {
    min_size     = each.value.min_size
    max_size     = each.value.max_size
    desired_size = each.value.desired_size
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
