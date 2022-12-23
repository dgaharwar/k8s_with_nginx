// Amazon EKS kubernetes cluster variables
variable "k8s_version" {
    default = "1.21"
}

variable "vpc_name" {
    default = "academy-vpc"
}

variable "cluster_name" {
    default = "academy-eks"
}

variable "region" {
    default = "eu-west-2"
}