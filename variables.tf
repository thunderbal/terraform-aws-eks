# variables.tf

variable "name" {
  description = "EKS cluster name."
  type        = string
  default     = "default"
}

variable "eks_version" {
  description = "Desired Kubernetes master version."
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "List of subnets for EKS cluster."
  type        = list(string)
}

variable "eks_addons" {
  description = "List of EKS AddOns to deploy."
  type        = map(any)
  default = {
    vpc-cni    = {}
    coredns    = {}
    kube-proxy = {}
  }
}

variable "eks_farget_profiles" {
  description = "List of Farget profiles to deploy."
  type        = map(any)
  default = {
    default = {
      namespace = "*"
    }
  }
}

variable "eks_node_groups" {
  description = "List of AWS managed node groups to deploy."
  type        = map(any)
  default     = {}
}
