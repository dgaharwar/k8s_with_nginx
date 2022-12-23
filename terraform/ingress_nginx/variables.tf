//NGINX Ingress variables
variable "ingress_nginx_repository" {
    default = "https://kubernetes.github.io/ingress-nginx"
}

variable "ingress_nginx_chart" {
    default = "ingress-nginx"
}

variable "ingress_nginx_version" {
    default = "4.0.16"
}

variable "ingress_nginx_name" {
    default = "ingress-nginx"
}

variable "ingress_nginx_namespace" {
    default = "ingress-nginx"
}

// NGINX Ingress Configuration
variable "ingress_nginx_values" {
}