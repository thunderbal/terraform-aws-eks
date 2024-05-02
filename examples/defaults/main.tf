# main.tf

module "network" {
  source = "git::https://github.com/thunderbal/terraform-aws-vpc-factory?ref=63ab9d90a177b09a45fe2d13b2bd3c247083133a" #v0.2.0
  # missing tag on public subnets: kubernetes.io/role/elb=1
  # missing tag on private subnets: kubernetes.io/role/internal-elb=1
}

module "eks" {
  source     = "../.."
  subnet_ids = module.network.subnet_ids.private
  depends_on = [module.network]
}
