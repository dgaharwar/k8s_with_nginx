// NGINX Ingress
resource "helm_release" "ingress_nginx" {
    name        = var.ingress_nginx_name
    repository  = var.ingress_nginx_repository
    chart       = var.ingress_nginx_chart
    version     = var.ingress_nginx_version
    namespace   = var.ingress_nginx_namespace
    create_namespace = true

    values = [var.ingress_nginx_values]
}