provider "aws" {
  version = "~> 2.67.0"
  region  = var.region
  alias   = "management_dns"

  assume_role {
    role_arn = "arn:aws:iam::${local.account["management"]}:role/${var.assume_role}"
  }
}

locals {
  fqdn = join(".", [var.name, local.parent_domain_name[local.environment]])
}

resource "aws_route53_record" "monitoring_loadbalancer" {
  count   = local.is_management_env ? 1 : 0
  name    = join(".", [local.roles[local.primary_role_index], local.fqdn])
  type    = "A"
  zone_id = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id

  alias {
    evaluate_target_health = false
    name                   = aws_lb.monitoring[0].dns_name
    zone_id                = aws_lb.monitoring[0].zone_id
  }

  provider = aws.management_dns
}

resource "aws_acm_certificate" "monitoring" {
  count             = local.is_management_env ? 1 : 0
  domain_name       = join(".", [local.roles[count.index], local.fqdn])
  validation_method = "DNS"
}

resource "aws_route53_record" "monitoring" {
  count   = local.is_management_env ? 1 : 0
  name    = aws_acm_certificate.monitoring[0].domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.monitoring[0].domain_validation_options.0.resource_record_type
  zone_id = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id
  records = [aws_acm_certificate.monitoring[0].domain_validation_options.0.resource_record_value]
  ttl     = 60

  provider = aws.management_dns
}

resource "aws_acm_certificate_validation" "monitoring" {
  count                   = local.is_management_env ? 1 : 0
  certificate_arn         = aws_acm_certificate.monitoring[0].arn
  validation_record_fqdns = [aws_route53_record.monitoring[0].fqdn]
}
