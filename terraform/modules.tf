module "subnet_addresses" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = var.base_cidr_block
  networks        = local.subnet_definitions
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "v3.0.0"

  name                   = var.stack_name
  cidr                   = module.subnet_addresses.base_cidr_block
  azs                    = [data.aws_availability_zones.this.names[0], data.aws_availability_zones.this.names[1]]
  private_subnets        = local.private_subnet_cidrs
  public_subnets         = local.public_subnet_cidrs
  enable_dns_hostnames   = true
  enable_dns_support     = true
  enable_ipv6            = true
  enable_nat_gateway     = false
  single_nat_gateway     = false
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false
  private_subnet_tags    = local.private_subnet_tags
  public_subnet_tags     = local.public_subnet_tags
  vpc_tags               = local.vpc_tags
  tags                   = local.module_tags.vpc
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "v17.0.3"

  cluster_name                   = var.stack_name
  cluster_version                = "1.20" // "1.21"
  subnets                        = module.vpc.public_subnets
  attach_worker_cni_policy       = true
  cluster_create_security_group  = true
  cluster_endpoint_public_access = true
  manage_aws_auth                = true
  manage_cluster_iam_resources   = true
  manage_worker_iam_resources    = true
  vpc_id                         = module.vpc.vpc_id
  # node_groups                    = local.node_groups
  # node_groups_defaults           = local.node_groups_defaults
  map_users        = local.map_users
  write_kubeconfig = false
  enable_irsa      = true
  worker_groups = [
    {
      name                 = "worker-group-1"
      instance_type        = "t3.medium"
      asg_desired_capacity = 1
      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "false"
          "value"               = "true"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${var.stack_name}"
          "propagate_at_launch" = "false"
          "value"               = "owned"
        }
      ]
    }
  ]
}

module "iam_assumable_role_admin" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "3.6.0"

  create_role                   = true
  role_name                     = "cluster-autoscaler"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.cluster_autoscaler.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.k8s_service_account_namespace}:${local.k8s_service_account_name}"]
}

module "iam_assumable_role_alb_controller" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "3.6.0"

  create_role                   = true
  role_name                     = "aws-load-balancer-controller"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.alb_controller.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
}
