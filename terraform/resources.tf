resource "aws_iam_policy" "cluster_autoscaler" {
  name_prefix = "cluster-autoscaler"
  description = "EKS cluster-autoscaler policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json
}

resource "aws_iam_policy" "alb_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "EKS ALB controller policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.alb_controller.json
}

resource "kubernetes_service_account" "this" {
  automount_service_account_token = true

  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${data.aws_caller_identity.current.id}:role/aws-load-balancer-controller" // module.iam_assumable_role_alb_controller.iam_role_arn
    }

    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/component"  = "controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

