# iam.tf



# -----------------------------------------------------------------------------
# - IAM OIDC Identity Provider for EKS
resource "aws_iam_openid_connect_provider" "self" {
  url             = aws_eks_cluster.self.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.self.certificates[0].sha1_fingerprint]
}



# -----------------------------------------------------------------------------
# - Role for EKS Cluster Controle Plane
data "aws_iam_policy_document" "eks_cluster_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  name_prefix        = local.name_prefix
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  for_each   = toset(["AmazonEKSClusterPolicy"])
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}



# -----------------------------------------------------------------------------
# - Role for EKS Fargate Profile
data "aws_iam_policy_document" "eks_fargate_assume" {
  count = length(local.eks_farget_profiles) > 0 ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [join(":", [
        "arn:aws:eks",
        local.aws_region,
        local.aws_account,
        join("/", ["fargateprofile", local.name_prefix, "*"])
      ])]
    }
  }
}

resource "aws_iam_role" "eks_fargate" {
  count              = length(local.eks_farget_profiles) > 0 ? 1 : 0
  name_prefix        = join("-", [local.name_prefix, "fargate"])
  assume_role_policy = data.aws_iam_policy_document.eks_fargate_assume[0].json
}

resource "aws_iam_role_policy_attachment" "eks_fargate" {
  for_each   = length(local.eks_farget_profiles) < 1 ? [] : toset(["AmazonEKSFargatePodExecutionRolePolicy"])
  role       = aws_iam_role.eks_fargate[0].name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}



# -----------------------------------------------------------------------------
# - Role for EKS Nodes
data "aws_iam_policy_document" "eks_node_assume" {
  count = length(local.eks_node_groups) > 0 ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_node" {
  count              = length(local.eks_node_groups) > 0 ? 1 : 0
  name_prefix        = join("-", [local.name_prefix, "node"])
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume[0].json
}

resource "aws_iam_role_policy_attachment" "eks_node" {
  for_each   = length(local.eks_node_groups) < 1 ? [] : toset(["AmazonEKSWorkerNodePolicy", "AmazonEC2ContainerRegistryReadOnly"])
  role       = aws_iam_role.eks_node[0].name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}



# -----------------------------------------------------------------------------
# - Role for VPC CNI plugin ()
data "aws_iam_policy_document" "eks_addons_assume" {
  for_each = local.eks_addons_policies

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${local.aws_account}:oidc-provider/oidc.eks.${local.aws_region}.amazonaws.com/id/${local.eks_oidc_id}"]
    }

    condition {
      test     = "StringEquals"
      variable = "oidc.eks.${local.aws_region}.amazonaws.com/id/${local.eks_oidc_id}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "oidc.eks.${local.aws_region}.amazonaws.com/id/${local.eks_oidc_id}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
  }
}

resource "aws_iam_role" "eks_addons" {
  for_each           = local.eks_addons_policies
  name_prefix        = join("-", [local.name_prefix, each.key])
  assume_role_policy = data.aws_iam_policy_document.eks_addons_assume[each.key].json
}

resource "aws_iam_role_policy_attachment" "eks_addons" { # TODO
  for_each = merge(flatten([for k, v in local.eks_addons_policies : { for p in v : join("_", [k, p]) => {
    role   = k
    policy = p
  } }])...)
  # for_each = contains(keys(local.eks_addons), "vpc-cni") ? toset(["AmazonEKS_CNI_Policy"]) : []
  role       = aws_iam_role.eks_addons[each.value.role].name
  policy_arn = "arn:aws:iam::aws:policy/${each.value.policy}"
}
