terraform {
	required_version = ">=1.0.6"

    required_providers {

        kubernetes = {
            source = "hashicorp/kubernetes"
            version = "~> 2.7.1"
        }
        helm = {
            source = "hashicorp/helm"
            version = "~> 2.4.1"
        }
        aws = {
            source  = "hashicorp/aws"
            version = ">= 3.74.0"
        }
    }
}

provider "aws" {
    region = "eu-west-2"
    access_key = var.access_key
    secret_key = var.secret_key
}


data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}


provider "helm" {
  kubernetes {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  }
}


resource "helm_release" "mam4pro" {
    name        = var.release_name
    chart       = var.chart
    namespace   = var.namespace
    create_namespace = true
    wait = false
    set {
        name = "scapture.replicas"
        value = var.scapture_replicas
    }
}