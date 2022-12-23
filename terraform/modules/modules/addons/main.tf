module "aws_vpc_cni" {
  count         = var.enable_amazon_eks_vpc_cni ? 1 : 0
  source        = "./aws-vpc-cni"
  addon_config  = var.amazon_eks_vpc_cni_config
  addon_context = local.addon_context
  enable_ipv6   = var.enable_ipv6
}

module "aws_coredns" {
  count         = var.enable_amazon_eks_coredns ? 1 : 0
  source        = "./aws-coredns"
  addon_config  = var.amazon_eks_coredns_config
  addon_context = local.addon_context
}

module "aws_kube_proxy" {
  count         = var.enable_amazon_eks_kube_proxy ? 1 : 0
  source        = "./aws-kube-proxy"
  addon_config  = var.amazon_eks_kube_proxy_config
  addon_context = local.addon_context
}

module "cluster_autoscaler" {
  count             = var.enable_cluster_autoscaler ? 1 : 0
  source            = "./cluster-autoscaler"
  helm_config       = var.cluster_autoscaler_helm_config
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = local.addon_context
}