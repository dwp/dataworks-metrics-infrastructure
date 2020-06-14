provider "aws" {
  version = "~> 2.57.0"
  region  = var.region
  alias   = "management_dns"

  assume_role {
    role_arn = "arn:aws:iam::${local.account["management"]}:role/${var.assume_role}"
  }
}

locals {
  fqdn = join(".", [var.name, local.parent_domain_name[local.environment]])
}

resource "aws_route53_record" "prometheus" {
  name    = local.fqdn
  type    = "A"
  zone_id = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id

  alias {
    evaluate_target_health = false
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
  }

  provider = aws.management_dns
}

resource "aws_acm_certificate" "prometheus" {
  domain_name       = local.fqdn
  validation_method = "DNS"
}

resource "aws_route53_record" "prometheus_validation" {
  name    = aws_acm_certificate.prometheus.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.prometheus.domain_validation_options.0.resource_record_type
  zone_id = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id
  records = [aws_acm_certificate.prometheus.domain_validation_options.0.resource_record_value]
  ttl     = 60

  provider = aws.management_dns
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.prometheus.arn
  validation_record_fqdns = [aws_route53_record.prometheus_validation.fqdn]
}
