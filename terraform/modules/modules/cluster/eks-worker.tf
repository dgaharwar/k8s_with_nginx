# ---------------------------------------------------------------------------------------------------------------------
# MANAGED NODE GROUPS
# ---------------------------------------------------------------------------------------------------------------------

module "aws_eks_managed_node_groups" {
  source = "./aws-eks-managed-node-groups"

  for_each = { for key, value in var.managed_node_groups : key => value
    if length(var.managed_node_groups) > 0
  }

  managed_ng = each.value
  context    = local.node_group_context

  depends_on = [kubernetes_config_map.aws_auth]
}

# ---------------------------------------------------------------------------------------------------------------------
# SELF MANAGED NODE GROUPS
# ---------------------------------------------------------------------------------------------------------------------

module "aws_eks_self_managed_node_groups" {
  source = "./aws-eks-self-managed-node-groups"

  for_each = { for key, value in var.self_managed_node_groups : key => value
    if length(var.self_managed_node_groups) > 0
  }

  self_managed_ng = each.value
  context         = local.node_group_context

  depends_on = [kubernetes_config_map.aws_auth]
}