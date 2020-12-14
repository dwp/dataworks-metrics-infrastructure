provider "aws" {
  version = "~> 2.68.0"
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
  provider = aws.management_dns
  count    = local.is_management_env ? 1 : 0
  name     = join(".", [local.roles[local.primary_role_index], local.fqdn])
  type     = "A"
  zone_id  = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id

  alias {
    evaluate_target_health = false
    name                   = aws_lb.monitoring[0].dns_name
    zone_id                = aws_lb.monitoring[0].zone_id
  }
}

resource "aws_route53_record" "thanos_query_loadbalancer" {
  provider = aws.management_dns
  count    = local.is_management_env ? 1 : 0
  name     = "thanos-query.${local.fqdn}"
  type     = "A"
  zone_id  = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id

  alias {
    evaluate_target_health = false
    name                   = aws_lb.monitoring[0].dns_name
    zone_id                = aws_lb.monitoring[0].zone_id
  }
}

resource "aws_route53_record" "thanos_ruler_loadbalancer" {
  provider = aws.management_dns
  count    = local.is_management_env ? 1 : 0
  name     = "thanos-ruler.${local.fqdn}"
  type     = "A"
  zone_id  = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id

  alias {
    evaluate_target_health = false
    name                   = aws_lb.monitoring[0].dns_name
    zone_id                = aws_lb.monitoring[0].zone_id
  }
}

resource "aws_route53_record" "thanos_store_loadbalancer" {
  provider = aws.management_dns
  count    = local.is_management_env ? 1 : 0
  name     = "thanos-store.${local.fqdn}"
  type     = "A"
  zone_id  = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id

  alias {
    evaluate_target_health = false
    name                   = aws_lb.monitoring[0].dns_name
    zone_id                = aws_lb.monitoring[0].zone_id
  }
}

resource "aws_route53_record" "grafana_loadbalancer" {
  provider = aws.management_dns
  count    = local.is_management_env ? 1 : 0
  name     = "grafana.${local.fqdn}"
  type     = "A"
  zone_id  = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id

  alias {
    evaluate_target_health = false
    name                   = aws_lb.monitoring[0].dns_name
    zone_id                = aws_lb.monitoring[0].zone_id
  }
}

resource "aws_route53_record" "alertmanager_loadbalancer" {
  provider = aws.management_dns
  count    = local.is_management_env ? 1 : 0
  name     = "alertmanager.${local.fqdn}"
  type     = "A"
  zone_id  = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id

  alias {
    evaluate_target_health = false
    name                   = aws_lb.monitoring[0].dns_name
    zone_id                = aws_lb.monitoring[0].zone_id
  }
}

resource "aws_route53_record" "outofband_loadbalancer" {
  provider = aws.management_dns
  count    = local.is_management_env ? 1 : 0
  name     = "outofband.${local.fqdn}"
  type     = "A"
  zone_id  = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id

  alias {
    evaluate_target_health = false
    name                   = aws_lb.monitoring[0].dns_name
    zone_id                = aws_lb.monitoring[0].zone_id
  }
}

resource "aws_acm_certificate" "monitoring" {
  count                     = local.is_management_env ? 1 : 0
  domain_name               = local.fqdn
  validation_method         = "DNS"
  subject_alternative_names = ["thanos-query.${local.fqdn}", "thanos-ruler.${local.fqdn}", "grafana.${local.fqdn}", "alertmanager.${local.fqdn}", "outofband.${local.fqdn}", "thanos-store.${local.fqdn}"]

  lifecycle {
    ignore_changes = [subject_alternative_names]
  }

  tags = merge(local.tags, { Name = var.name })
}

resource "aws_route53_record" "monitoring" {
  provider = aws.management_dns
  count    = local.is_management_env ? 1 : 0
  name     = aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.0.resource_record_name
  type     = aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.0.resource_record_type
  zone_id  = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id
  records  = [aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.0.resource_record_value]
  ttl      = 60
}

resource "aws_route53_record" "thanos_query" {
  provider = aws.management_dns
  count    = local.is_management_env ? 1 : 0
  name     = aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.1.resource_record_name
  type     = aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.1.resource_record_type
  zone_id  = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id
  records  = [aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.1.resource_record_value]
  ttl      = 60
}

resource "aws_route53_record" "thanos_ruler" {
  provider = aws.management_dns
  count    = local.is_management_env ? 1 : 0
  name     = aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.2.resource_record_name
  type     = aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.2.resource_record_type
  zone_id  = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id
  records  = [aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.2.resource_record_value]
  ttl      = 60
}

resource "aws_route53_record" "grafana" {
  provider = aws.management_dns
  count    = local.is_management_env ? 1 : 0
  name     = aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.3.resource_record_name
  type     = aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.3.resource_record_type
  zone_id  = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id
  records  = [aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.3.resource_record_value]
  ttl      = 60
}

resource "aws_route53_record" "alertmanager" {
  provider = aws.management_dns
  count    = local.is_management_env ? 1 : 0
  name     = aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.4.resource_record_name
  type     = aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.4.resource_record_type
  zone_id  = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id
  records  = [aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.4.resource_record_value]
  ttl      = 60
}

resource "aws_route53_record" "outofband" {
  provider = aws.management_dns
  count    = local.is_management_env ? 1 : 0
  name     = aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.5.resource_record_name
  type     = aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.5.resource_record_type
  zone_id  = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id
  records  = [aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.5.resource_record_value]
  ttl      = 60
}

resource "aws_route53_record" "thanos_store" {
  provider = aws.management_dns
  count    = local.is_management_env ? 1 : 0
  name     = aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.6.resource_record_name
  type     = aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.6.resource_record_type
  zone_id  = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id
  records  = [aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options.6.resource_record_value]
  ttl      = 60
}

resource "aws_acm_certificate_validation" "monitoring" {
  count           = local.is_management_env ? 1 : 0
  certificate_arn = aws_acm_certificate.monitoring[local.primary_role_index].arn
  validation_record_fqdns = [
    aws_route53_record.monitoring[local.primary_role_index].fqdn,
    aws_route53_record.thanos_query[local.primary_role_index].fqdn,
    aws_route53_record.thanos_ruler[local.primary_role_index].fqdn,
    aws_route53_record.grafana[local.primary_role_index].fqdn,
    aws_route53_record.alertmanager[local.primary_role_index].fqdn,
    aws_route53_record.outofband[local.primary_role_index].fqdn
//    aws_route53_record.thanos_store[local.primary_role_index].fqdn
  ]
}
