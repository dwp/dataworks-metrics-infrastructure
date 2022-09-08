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
  subject_alternative_names = ["thanos-query.${local.fqdn}", "thanos-ruler.${local.fqdn}", "grafana.${local.fqdn}", "alertmanager.${local.fqdn}", "outofband.${local.fqdn}"]

  lifecycle {
    ignore_changes = [subject_alternative_names]
  }

  tags = merge(local.tags, { Name = var.name })
}

resource "aws_route53_record" "monitoring" {
  provider        = aws.management_dns
  count           = local.is_management_env ? 1 : 0
  name            = tolist(aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options)[0].resource_record_name
  type            = tolist(aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options)[0].resource_record_type
  zone_id         = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id
  records         = [tolist(aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options)[0].resource_record_value]
  ttl             = 60
  allow_overwrite = true

}

resource "aws_route53_record" "thanos_query" {
  provider        = aws.management_dns
  count           = local.is_management_env ? 1 : 0
  name            = tolist(aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options)[1].resource_record_name
  type            = tolist(aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options)[1].resource_record_type
  zone_id         = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id
  records         = [tolist(aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options)[1].resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_route53_record" "thanos_ruler" {
  provider        = aws.management_dns
  count           = local.is_management_env ? 1 : 0
  name            = tolist(aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options)[2].resource_record_name
  type            = tolist(aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options)[2].resource_record_type
  zone_id         = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id
  records         = [tolist(aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options)[2].resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_route53_record" "grafana" {
  provider        = aws.management_dns
  count           = local.is_management_env ? 1 : 0
  name            = tolist(aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options)[3].resource_record_name
  type            = tolist(aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options)[3].resource_record_type
  zone_id         = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id
  records         = [tolist(aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options)[3].resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_route53_record" "alertmanager" {
  provider        = aws.management_dns
  count           = local.is_management_env ? 1 : 0
  name            = tolist(aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options)[4].resource_record_name
  type            = tolist(aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options)[4].resource_record_type
  zone_id         = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id
  records         = [tolist(aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options)[4].resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_route53_record" "outofband" {
  provider        = aws.management_dns
  count           = local.is_management_env ? 1 : 0
  name            = tolist(aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options)[5].resource_record_name
  type            = tolist(aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options)[5].resource_record_type
  zone_id         = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id
  records         = [tolist(aws_acm_certificate.monitoring[local.primary_role_index].domain_validation_options)[5].resource_record_value]
  ttl             = 60
  allow_overwrite = true
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
  ]
}

resource "aws_route53_vpc_association_authorization" "monitoring" {
  count   = local.is_management_env ? 0 : 1
  vpc_id  = local.is_management_env ? module.vpc.outputs.vpcs[0].id : data.terraform_remote_state.management_dmi.outputs.vpcs[0].id
  zone_id = aws_service_discovery_private_dns_namespace.monitoring.hosted_zone
}

resource "aws_route53_zone_association" "monitoring" {
  for_each   = local.is_management_env ? local.dns_zone_ids[local.environment] : {}
  provider   = aws.management_zone
  vpc_id     = module.vpc.outputs.vpcs[0].id
  zone_id    = each.value
  depends_on = [aws_route53_vpc_association_authorization.monitoring]
}

resource "aws_route53_vpc_association_authorization" "sdx_services" {
  count   = local.is_management_env ? 0 : 1
  vpc_id  = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id = data.terraform_remote_state.aws_sdx.outputs.private_dns.sdx_service_discovery_dns.hosted_zone
}

resource "aws_route53_zone_association" "sdx_services" {
  count      = local.is_management_env ? 0 : 1
  provider   = aws.non_management_zone
  vpc_id     = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id    = local.is_management_env ? null_resource.dummy.id : local.sdx_dns_zone_ids[local.environment]
  depends_on = [aws_route53_vpc_association_authorization.sdx_services]
}

resource "aws_route53_vpc_association_authorization" "pdm_services" {
  count   = local.is_management_env ? 0 : 1
  vpc_id  = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id = data.terraform_remote_state.aws_pdm_dataset_generation.outputs.private_dns.pdm_service_discovery_dns.hosted_zone
}

resource "aws_route53_zone_association" "pdm_services" {
  count      = local.is_management_env ? 0 : 1
  provider   = aws.non_management_zone
  vpc_id     = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id    = local.is_management_env ? null_resource.dummy.id : local.pdm_dns_zone_ids[local.environment]
  depends_on = [aws_route53_vpc_association_authorization.pdm_services]
}

resource "aws_route53_vpc_association_authorization" "adg_services" {
  count   = local.is_management_env ? 0 : 1
  vpc_id  = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id = data.terraform_remote_state.aws_analytical_dataset_generation.outputs.private_dns.adg_service_discovery_dns.hosted_zone
}

resource "aws_route53_zone_association" "adg_services" {
  count      = local.is_management_env ? 0 : 1
  provider   = aws.non_management_zone
  vpc_id     = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id    = local.is_management_env ? null_resource.dummy.id : local.adg_dns_zone_ids[local.environment]
  depends_on = [aws_route53_vpc_association_authorization.adg_services]
}

resource "aws_route53_vpc_association_authorization" "clive_services" {
  count   = local.is_management_env ? 0 : 1
  vpc_id  = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id = data.terraform_remote_state.aws_clive.outputs.private_dns.clive_service_discovery_dns.hosted_zone
}

resource "aws_route53_zone_association" "clive_services" {
  count      = local.is_management_env ? 0 : 1
  provider   = aws.non_management_zone
  vpc_id     = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id    = local.is_management_env ? null_resource.dummy.id : local.clive_dns_zone_ids[local.environment]
  depends_on = [aws_route53_vpc_association_authorization.clive_services]
}
resource "aws_route53_vpc_association_authorization" "htme_services" {
  count   = local.is_management_env ? 0 : 1
  vpc_id  = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id = data.terraform_remote_state.aws_internal_compute.outputs.private_dns.htme_service_discovery_dns.hosted_zone
}

resource "aws_route53_zone_association" "htme_services" {
  count      = local.is_management_env ? 0 : 1
  provider   = aws.non_management_zone
  vpc_id     = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id    = local.is_management_env ? null_resource.dummy.id : local.htme_dns_zone_ids[local.environment]
  depends_on = [aws_route53_vpc_association_authorization.htme_services]
}
resource "aws_route53_zone_association" "uc_feature_services" {
  count      = local.is_management_env ? 0 : 1
  provider   = aws.non_management_zone
  vpc_id     = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id    = local.is_management_env ? null_resource.dummy.id : local.uc_feature_dns_zone_ids[local.environment]
  depends_on = [aws_route53_vpc_association_authorization.uc_feature_services]
}

resource "aws_route53_vpc_association_authorization" "uc_feature_services" {
  count   = local.is_management_env ? 0 : 1
  vpc_id  = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id = data.terraform_remote_state.aws_uc_feature.outputs.private_dns.uc_feature_service_discovery_dns.hosted_zone
}

resource "aws_route53_zone_association" "cyi_services" {
  count      = local.is_management_env ? 0 : 1
  provider   = aws.non_management_zone
  vpc_id     = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id    = local.is_management_env ? null_resource.dummy.id : local.cyi_dns_zone_ids[local.environment]
  depends_on = [aws_route53_vpc_association_authorization.cyi_services]
}

resource "aws_route53_vpc_association_authorization" "cyi_services" {
  count   = local.is_management_env ? 0 : 1
  vpc_id  = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id = data.terraform_remote_state.aws_cyi.outputs.private_dns.cyi_service_discovery_dns.hosted_zone
}

resource "aws_route53_vpc_association_authorization" "kickstart_adg_services" {
  count   = local.is_management_env ? 0 : 1
  vpc_id  = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id = data.terraform_remote_state.dataworks_aws_kickstart_adg.outputs.private_dns.kickstart_adg_service_discovery_dns.hosted_zone
}

resource "aws_route53_zone_association" "kickstart_adg_services" {
  count      = local.is_management_env ? 0 : 1
  provider   = aws.non_management_zone
  vpc_id     = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id    = local.is_management_env ? null_resource.dummy.id : local.kickstart_adg_dns_zone_ids[local.environment]
  depends_on = [aws_route53_vpc_association_authorization.kickstart_adg_services]
}

resource "aws_route53_vpc_association_authorization" "mongo_latest_services" {
  count   = local.is_management_env ? 0 : 1
  vpc_id  = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id = data.terraform_remote_state.dataworks_aws_mongo_latest.outputs.private_dns.mongo_latest_service_discovery_dns.hosted_zone
}

resource "aws_route53_zone_association" "mongo_latestservices" {
  count      = local.is_management_env ? 0 : 1
  provider   = aws.non_management_zone
  vpc_id     = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id    = local.is_management_env ? null_resource.dummy.id : local.mongo_latest_dns_zone_ids[local.environment]
  depends_on = [aws_route53_vpc_association_authorization.mongo_latest_services]
}

resource "aws_route53_vpc_association_authorization" "ucfs_claimant_services" {
  count   = local.is_management_env ? 0 : 1
  vpc_id  = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id = data.terraform_remote_state.ucfs-claimant.outputs.private_dns.ucfs_claimant_api_service_discovery_dns.hosted_zone
}

resource "aws_route53_zone_association" "ucfs_claimant_services" {
  count      = local.is_management_env ? 0 : 1
  provider   = aws.non_management_zone
  vpc_id     = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id    = local.is_management_env ? null_resource.dummy.id : local.ucfs_claimant_dns_zone_ids[local.environment]
  depends_on = [aws_route53_vpc_association_authorization.ucfs_claimant_services]
}

resource "aws_route53_vpc_association_authorization" "analytical_frontend_services" {
  count   = local.is_management_env ? 0 : 1
  vpc_id  = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id = data.terraform_remote_state.analytical-frontend-service.outputs.frontend_service.frontend_service_discovery_dns.hosted_zone
}


resource "aws_route53_zone_association" "analytical_frontend_services" {
  count      = local.is_management_env ? 0 : 1
  provider   = aws.non_management_zone
  vpc_id     = local.is_management_env ? null_resource.dummy.id : module.vpc.outputs.vpcs[0].id
  zone_id    = local.is_management_env ? null_resource.dummy.id : local.analytical_frontend_dns_zone_ids[local.environment]
  depends_on = [aws_route53_vpc_association_authorization.analytical_frontend_services]
}
