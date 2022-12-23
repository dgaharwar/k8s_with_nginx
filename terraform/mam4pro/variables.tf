//NGINX Ingress variables

variable "cluster_name" {
    default= "academy-eks"
}


# variable "k8s_token" {
# }


variable "access_key" {
    default = ""
}

variable "secret_key" {
    default = ""
}

variable "chart"{
    default = "aws_mam4pro"
}

variable "namespace"{
    default = "mam4pro-terraform"
}

variable "release_name"{
    default = "mam4pro"
}


variable "scapture_replicas"{
    default = "1"
}