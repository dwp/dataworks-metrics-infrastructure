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
  count   = local.roles[0] == "master" ? 1 : 0
  name    = join(".", [local.roles[count.index], local.fqdn])
  type    = "A"
  zone_id = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id

  alias {
    evaluate_target_health = false
    name                   = aws_lb.lb[count.index].dns_name
    zone_id                = aws_lb.lb[count.index].zone_id
  }

  provider = aws.management_dns
}

resource "aws_acm_certificate" "prometheus" {
  count             = length(local.roles)
  domain_name       = join(".", [local.roles[count.index], local.fqdn])
  validation_method = "DNS"
}

resource "aws_route53_record" "prometheus_validation" {
  count   = length(local.roles)
  name    = aws_acm_certificate.prometheus[count.index].domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.prometheus[count.index].domain_validation_options.0.resource_record_type
  zone_id = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id
  records = [aws_acm_certificate.prometheus[count.index].domain_validation_options.0.resource_record_value]
  ttl     = 60

  provider = aws.management_dns
}

resource "aws_acm_certificate_validation" "cert" {
  count                   = length(local.roles)
  certificate_arn         = aws_acm_certificate.prometheus[count.index].arn
  validation_record_fqdns = [aws_route53_record.prometheus_validation[count.index].fqdn]
}
