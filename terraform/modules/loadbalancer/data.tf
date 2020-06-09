data "aws_route53_zone" "main" {
  name = var.parent_domain_name
}
