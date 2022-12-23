output "RELEASE_URL" {
  value = data.aws_lb.test.dns_name
}
output "RELEASE_USERNAME" {
  value = "admin"
}
output "RELEASE_PASSWORD" {
  value = "admin"
}

