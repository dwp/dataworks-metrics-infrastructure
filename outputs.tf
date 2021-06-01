output "vpcs" {
  value = module.vpc.outputs.vpcs
}

output "private_route_tables" {
  value = module.vpc.outputs.private_route_tables
}

output "thanos_security_group" {
  value = local.is_management_env ? aws_security_group.thanos_query[0].id : null_resource.dummy.id
}

output "azkaban_pushgateway_security_group" {
  value = local.is_management_env ? null_resource.dummy.id : aws_security_group.azkaban_pushgateway[0].id
}

output "azkaban_pushgateway_hostname" {
  value = local.is_management_env ? null_resource.dummy.id : "${aws_service_discovery_service.azkaban_pushgateway[0].name}.${aws_service_discovery_private_dns_namespace.azkaban_services[0].name}"
}

output "sdx_pushgateway_security_group" {
  value = local.is_management_env ? null_resource.dummy.id : aws_security_group.sdx_pushgateway[0].id
}

output "blackbox_security_group" {
  value = local.is_management_env ? null_resource.dummy.id : aws_security_group.blackbox[0].id
}

output "ingest_pushgateway_hostname" {
  value = local.is_management_env ? null_resource.dummy.id : "${aws_service_discovery_service.ingest_pushgateway[0].name}.${aws_service_discovery_private_dns_namespace.ingest_services[0].name}"
}

output "ucfs_pushgateway_security_group" {
  value = local.is_management_env ? null_resource.dummy.id : aws_security_group.ucfs_claimant_api_pushgateway[0].id
}

output "monitoring_bucket" {
  value = {
    id  = local.is_management_env ? aws_s3_bucket.monitoring[local.primary_role_index].id : null_resource.dummy.id
    arn = local.is_management_env ? aws_s3_bucket.monitoring[local.primary_role_index].arn : null_resource.dummy.id
    key = local.is_management_env ? aws_kms_key.monitoring_bucket_cmk[local.primary_role_index].arn : null_resource.dummy.id
  }
}

output "grafana_fqdn" {
  value = local.is_management_env ? aws_route53_record.grafana_loadbalancer[0].fqdn : null_resource.dummy.id
}

resource "null_resource" "dummy" {}

resource "null_resource" "dummy_2" {}
