terraform {
  required_version = "=0.14.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.74.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.7.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.4.1"
    }
  }
}

provider "aws" {
  region     = module.cluster.region
  access_key = var.access_key
  secret_key = var.secret_key
}

provider "kubernetes" {
  host                   = module.cluster.host
  token                  = module.cluster.token
  cluster_ca_certificate = base64decode(module.cluster.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.cluster.host
    token                  = module.cluster.token
    cluster_ca_certificate = base64decode(module.cluster.cluster_ca_certificate)
  }
}

///////////////// DATA ///////////////////

// NGINX Ingress Configuration
data "template_file" "ingress_nginx_config" {
  template = file("${path.module}/ingress_nginx_values.yaml")
}

///////////////// MODULES ///////////////////

module "cluster" {
  source       = "./modules/"
  cluster_name = "${var.INSTANCE_NAME}_eks"
  vpc_name     = "${var.INSTANCE_NAME}_vpc"
}

module "ingress_nginx" {
  source               = "./ingress_nginx/"
  ingress_nginx_values = data.template_file.ingress_nginx_config.rendered
  depends_on           = [module.cluster.managed_node_groups]
}

resource "helm_release" "mam4pro" {
  name             = var.INSTANCE_NAME
  chart            = "./mam4pro/aws_mam4pro"
  namespace        = var.INSTANCE_NAME
  create_namespace = true
  timeout          = 1800
  #wait             = false
  set {
    name  = "scapture.replicas"
    value = sum([parseint(var.SERVICES_CAPTURE_HD_REPLICAS, 10), parseint(var.SERVICES_CAPTURE_FHD_REPLICAS, 10), parseint(var.SERVICES_CAPTURE_4K_REPLICAS, 10)])
  }

  set {
    name  = "rplayerweb.replicas"
    value = sum([parseint(var.SERVICES_PLAYER_HD_REPLICAS, 10), parseint(var.SERVICES_PLAYER_FHD_REPLICAS, 10), parseint(var.SERVICES_PLAYER_4K_REPLICAS, 10)])
  }
  set {
    name  = "hoperation.replicas"
    value = sum([parseint(var.SERVICES_INGEST_HD_REPLICAS, 10), parseint(var.SERVICES_INGEST_FHD_REPLICAS, 10), parseint(var.SERVICES_INGEST_4K_REPLICAS, 10)])
  }

}

locals {
  tagname = "kubernetes.io/cluster/${var.INSTANCE_NAME}_eks"
}

data "aws_lb" "test" {
  tags = {
    (local.tagname) = "owned"
  }
  depends_on = [module.cluster.managed_node_groups, resource.helm_release.mam4pro]
}
