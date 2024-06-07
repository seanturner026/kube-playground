module "subnet_addresses" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = var.base_cidr_block
  networks        = local.subnet_definitions
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "v3.18.1"

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
  version = "~> 19.4"

  cluster_name                   = var.stack_name
  cluster_version                = "1.25"
  subnet_ids                     = module.vpc.public_subnets
  vpc_id                         = module.vpc.vpc_id
  cluster_endpoint_public_access = true
  manage_aws_auth_configmap      = true
  enable_irsa                    = true
  create_kms_key                 = false

  eks_managed_node_groups = {
    # x86_spot = {
    #   ami_type       = "AL2_x86_64"
    #   min_size       = 1
    #   max_size       = 1
    #   desired_size   = 1
    #   instance_types = ["t3a.small"]
    #   capacity_type  = "SPOT"
    #   update_config  = { max_unavailable_percentage = 33 }

    #   tags = {
    #     "k8s.io/cluster-autoscaler/${var.stack_name}" = "owned"
    #     "k8s.io/cluster-autoscaler/enabled"           = "true"
    #   }
    # }
    arm_spot = {
      ami_type       = "AL2_ARM_64"
      min_size       = 1
      max_size       = 1
      desired_size   = 1
      instance_types = ["t4g.small"]
      capacity_type  = "SPOT"
      update_config  = { max_unavailable_percentage = 33 }

      tags = {
        "k8s.io/cluster-autoscaler/${var.stack_name}" = "owned"
        "k8s.io/cluster-autoscaler/enabled"           = "true"
      }
    }
  }

  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI = "true"
        }
        init = {
          env = {
            DISABLE_TCP_EARLY_DEMUX = "true"
          }
        }
      })
    }
  }

  aws_auth_users = [{
    userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.aws_iam_username}"
    username = var.aws_iam_username
    groups   = ["system:masters"]
  }]
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
