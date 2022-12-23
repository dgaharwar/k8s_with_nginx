terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.66.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.6.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4.1"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {
  name = var.region
}

data "aws_eks_cluster" "cluster" {
  name = module.aws-eks-accelerator-for-terraform.eks_cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.aws-eks-accelerator-for-terraform.eks_cluster_id
}

locals {
  tenant      = var.cluster_name  # AWS account name or unique id for tenant
  environment = "preprod" # Environment area eg., preprod or prod
  zone        = "aws"     # Environment with in one sub_tenant or business unit

  vpc_cidr     = "10.1.0.0/16"
  vpc_name     = var.vpc_name
  azs          = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "aws_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "v3.2.0"

  name = local.vpc_name
  cidr = local.vpc_cidr
  azs  = local.azs

  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  single_nat_gateway   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }

}

#---------------------------------------------------------------
# Example to consume aws-eks-accelerator-for-terraform module
#---------------------------------------------------------------
resource "aws_security_group" "additional_cluster_sg" {
    name_prefix = "additional_cluster_sg"
    vpc_id      = module.aws_vpc.vpc_id

    egress {//Allow all outbound traffic 
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # ingress {//Allow inbound SSH connections
    #     from_port = 22
    #     to_port   = 22
    #     protocol  = "tcp"
    #     cidr_blocks = ["0.0.0.0/0"]
    # }

    # ingress {//Allow inbound Remote Desktop connections
    #     from_port = 3389
    #     to_port   = 3389
    #     protocol  = "tcp"
    #     cidr_blocks = ["0.0.0.0/0"]
    # }

    # ingress {
    #     from_port = 1947
    #     to_port   = 1947
    #     protocol  = "tcp"
    #     cidr_blocks = ["0.0.0.0/0"]
    # }
}

//Here we extend the node security group rules with recommendations from
//https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html
resource "aws_security_group" "additional_worker_sg" {
  name_prefix = "additional_worker_sg"
  vpc_id      = module.aws_vpc.vpc_id

  ingress {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      self        = true
  }

  egress {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
  }

  //8443 port communication is necessary from nodes to master for the validatingwebhook API
  //https://github.com/kubernetes/ingress-nginx/issues/5401
  ingress {
      from_port = 8443
      to_port   = 8443
      protocol  = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "lin_ami" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amazon-eks-node-${var.k8s_version}-*"]
    }
}

module "aws-eks-accelerator-for-terraform" {
  source = "./modules/cluster/"

  cluster_name      = var.cluster_name
  tenant            = local.tenant
  environment       = local.environment
  zone              = local.zone

  # EKS Cluster VPC and Subnet mandatory config
  vpc_id             = module.aws_vpc.vpc_id
  private_subnet_ids = module.aws_vpc.private_subnets

  # EKS CONTROL PLANE VARIABLES
  cluster_version = var.k8s_version

  # EKS SECURITY GROUPS
  cluster_additional_security_group_ids = [aws_security_group.additional_cluster_sg.id]

  //Cluster Security Group Rules (Control-plane <=> Nodes/Kubelets)
  //The module BY DEFAULT adds 3 cluster sg rules with the following objectives:
  //- Allow 443 TCP inbound/outbound communication between CP and Nodes
  //- Allow 10250 TCP outbound communication from CP to Kubelets
  cluster_security_group_additional_rules = {
      //Here we extend the cluster security group rules with recommendations from
      //https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html
      egress_nodes_ephemeral_ports_tcp = {
          description                = "To node 1025-65535"
          protocol                   = "tcp"
          from_port                  = 1025
          to_port                    = 65535
          type                       = "egress"
          source_node_security_group = true
      }
  }

  //Node Security Group Rules (Node <=> Nodes)
  //The module BY DEFAULT adds 10 node sg rules with the following objectives:
  //- Allow 443 TCP inbound/outbound communication between Nodes and CP 
  //- Allow 10250 TCP inbound communication to Kubelets from CP
  //- Allow 53 TCP/UDP inbound/outbound CoreDNS communication
  //- Allow 443 TCP outbound communication to the internet
  //- Allow 123 TCP/UDP outbound NTP communication
  worker_additional_security_group_ids = [aws_security_group.additional_worker_sg.id]

  # Linux Nodes as EKS Managed Node Group
  managed_node_groups = {
    mng_linux = {
      node_group_name = "mng_linux"

      # Launch template configuration
      # worker_additional_security_group_ids is only enabled when `create_launch_template  = true` for Managed Nodegroups
      create_launch_template  = true

      # Node Group scaling configuration
      desired_size    = "1"
      min_size        = "1"
      max_size        = "2"
      max_unavailable = "1"

      # Node Group compute configuration
      # When creating a Managed node group with a launch template, the behavior differs based on whether an AMI has been specified in the launch template or not.
      # When no AMI is present in the launch template, EKS will merge in a section of MIME multi-part user data to the user data contents you've passed in.
      # The part EKS merges in will attempt to bootstrap your worker node as well.
      # Since MIME multiparts are executed in order, this means your bootstrapping happens first and the EKS bootstrapping becomes a no-op.
      # As a result, your worker nodes don't have the required labels for EKS to associate them with a node group.
      ami_type        = "CUSTOM"
      custom_ami_id   = data.aws_ami.lin_ami.id
      capacity_type   = "ON_DEMAND"
      instance_types  = ["t3.medium"]
      disk_size       = 30

      # Node Group network configuration
      subnet_ids      = module.aws_vpc.private_subnets
    }
  }

  # Windows Nodes as Self-Managed Node Group with Windows support
  enable_windows_support = true

  self_managed_node_groups = {
    smng_windows = {
      node_group_name    = "smng_windows"
      launch_template_os = "windows"
      instance_type      = "t3.large"
      subnet_ids         = module.aws_vpc.private_subnets
      min_size           = "1"
      max_size           = "1"
    }
  }
}

module "kubernetes-addons" {
  source = "./modules/addons/"

  eks_cluster_id = module.aws-eks-accelerator-for-terraform.eks_cluster_id

  # EKS Managed Add-ons
  enable_amazon_eks_vpc_cni    = true
  enable_amazon_eks_coredns    = true
  enable_amazon_eks_kube_proxy = true

  # K8s Add-ons
  # Ensure proper node assignment
  enable_cluster_autoscaler = true
  cluster_autoscaler_helm_config = {
    set = [
      {
        name  = "nodeSelector.kubernetes\\.io/os"
        value = "linux"
      }
    ]
  }

  depends_on = [module.aws-eks-accelerator-for-terraform.managed_node_groups]
}

output "region" {
    value = var.region
}

output "host" {
    value = data.aws_eks_cluster.cluster.endpoint
}

output "token" {
    value = data.aws_eks_cluster_auth.cluster.token
}

output "cluster_ca_certificate" {
    value = data.aws_eks_cluster.cluster.certificate_authority.0.data
}

output "self_managed_node_groups" {
  value = module.aws-eks-accelerator-for-terraform.self_managed_node_groups
}

output "managed_node_groups" {
  value = module.aws-eks-accelerator-for-terraform.managed_node_groups
}

output "eks_cluster_id" {
    value = module.aws-eks-accelerator-for-terraform.eks_cluster_id
}
