locals {

  module_tags = {
    vpc = {
      ModuleRepo = "terraform-aws-vpc"
      ModuleOrg  = "terraform-aws-modules"
    }
    eks = {
      ModuleRepo = "terraform-aws-eks"
      ModuleOrg  = "terraform-aws-modules"
    }
  }

  subnet_definitions = [
    {
      name     = "private-a"
      new_bits = 6
    },
    {
      name     = "private-b"
      new_bits = 6
    },
    {
      name     = "public-a"
      new_bits = 6
    },
    {
      name     = "public-b"
      new_bits = 6
    },
  ]

  private_subnet_cidrs = [for network in module.subnet_addresses.networks : network.cidr_block if length(regexall("private", network.name)) > 0]
  public_subnet_cidrs  = [for network in module.subnet_addresses.networks : network.cidr_block if length(regexall("public", network.name)) > 0]

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  vpc_tags = {}

  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 10
  }

  k8s_service_account_namespace = "kube-system"
  k8s_service_account_name      = "cluster-autoscaler-aws-cluster-autoscaler-chart"
}
