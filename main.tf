# main.tf

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  aws_account       = data.aws_caller_identity.current.account_id
  aws_region        = data.aws_region.current.name
  name_prefix       = var.name
  eks_addons        = var.eks_addons
  eks_addons_latest = true
  eks_addons_policies = {
    vpc-cni = contains(keys(local.eks_addons), "vpc-cni") ? ["AmazonEKS_CNI_Policy"] : []
  }
  eks_farget_profiles = var.eks_farget_profiles
  eks_node_groups = {
    for k, v in var.eks_node_groups : k => {
      ami_type      = try(v.ami_type, "AL2023_x86_64_STANDARD")
      capacity_type = try(v.capacity_type, "SPOT")
      min_size      = try(v.min_size, 0)
      max_size      = try(v.max_size, length(var.subnet_ids))
      desired_size  = try(v.desired_size, v.min_size, 0)
    }
  }
}

data "aws_eks_addon_version" "self" {
  for_each           = local.eks_addons
  addon_name         = each.key
  kubernetes_version = aws_eks_cluster.self.version
  most_recent        = local.eks_addons_latest
}

data "tls_certificate" "self" {
  url = aws_eks_cluster.self.identity[0].oidc[0].issuer
}
