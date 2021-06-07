locals {

  module_tags = {
    vpc = {
      ModuleRepo    = "terraform-aws-vpc"
      ModuleVersion = "v3.0.0"
      ModuleOrg     = "terraform-aws-modules"
    }
    eks = {
      ModuleRepo    = "terraform-aws-eks"
      ModuleVersion = "v17.0.3"
      ModuleOrg     = "terraform-aws-modules"
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
    "kubernetes.io/cluster/${var.stack_name}" = "shared"
    "kubernetes.io/role/internal-elb"         = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.stack_name}" = "shared"
    "kubernetes.io/role/elb"                  = "1"
  }

  vpc_tags = {
    "kubernetes.io/cluster/${var.stack_name}" = "shared"
  }

  node_groups = {
    this = {
      desired_capacity = 1
      max_capacity     = 1
      min_capacity     = 1
      instance_type    = "t3a.small"
      capacity_type    = "SPOT",
      k8s_labels       = local.module_tags.eks

      additional_tags = {
        "k8s.io/cluster-autoscaler/enabled"           = "true"
        "k8s.io/cluster-autoscaler/${var.stack_name}" = "owned"
      }
    }
  }

  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 10
  }

  map_users = [{
    userarn  = "arn:aws:iam::${data.aws_caller_identity.current.id}:user/sean.turner"
    username = "sean.turner"
    groups   = ["system:masters"]
  }]

  k8s_service_account_namespace = "kube-system"
  k8s_service_account_name      = "cluster-autoscaler-aws-cluster-autoscaler-chart"
}
