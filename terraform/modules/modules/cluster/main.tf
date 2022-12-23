# ---------------------------------------------------------------------------------------------------------------------
# LABELING EKS RESOURCES
# ---------------------------------------------------------------------------------------------------------------------
module "eks_tags" {
  source      = "./aws-resource-tags"
  tenant      = var.tenant
  environment = var.environment
  zone        = var.zone
  resource    = "eks"
  tags        = var.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# EKS CONTROL PLANE
# ---------------------------------------------------------------------------------------------------------------------
module "aws_eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "v18.10.0"
  create  = var.create_eks

  cluster_name     = var.cluster_name
  cluster_version  = var.cluster_version
  cluster_timeouts = var.cluster_timeouts

  # IAM Role
  iam_role_use_name_prefix      = false
  iam_role_name                 = local.cluster_iam_role_name
  iam_role_path                 = var.iam_role_path
  iam_role_permissions_boundary = var.iam_role_permissions_boundary
  iam_role_additional_policies  = var.iam_role_additional_policies

  # EKS Cluster VPC Config
  subnet_ids                           = var.private_subnet_ids
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Kubernetes Network Config
  cluster_ip_family         = var.cluster_ip_family
  cluster_service_ipv4_cidr = var.cluster_service_ipv4_cidr

  # Cluster Security Group
  create_cluster_security_group           = true
  create_node_security_group              = true
  vpc_id                                  = var.vpc_id
  cluster_additional_security_group_ids   = var.cluster_additional_security_group_ids
  cluster_security_group_additional_rules = var.cluster_security_group_additional_rules

  # IRSA
  enable_irsa              = var.enable_irsa # no change
  openid_connect_audiences = var.openid_connect_audiences
  custom_oidc_thumbprints  = var.custom_oidc_thumbprints

  # TAGS
  tags = module.eks_tags.tags

  # CLUSTER LOGGING
  cluster_enabled_log_types              = var.cluster_enabled_log_types # no change
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id        = var.cloudwatch_log_group_kms_key_id
}

resource "kubernetes_config_map" "amazon_vpc_cni" {
  count = var.enable_windows_support ? 1 : 0
  metadata {
    name      = "amazon-vpc-cni"
    namespace = "kube-system"
  }

  data = {
    "enable-windows-ipam" = var.enable_windows_support ? "true" : "false"
  }

  depends_on = [
    module.aws_eks.cluster_id,
    data.http.eks_cluster_readiness[0]
  ]
}