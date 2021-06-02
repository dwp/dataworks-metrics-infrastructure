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

output "internet_proxy" {
  value = {
    url  = local.is_management_env ? format("http://%s:3128", aws_vpc_endpoint.internet_proxy[0].dns_entry[0].dns_name) : format("http://%s:3128", aws_vpc_endpoint.lower_internet_proxy[0].dns_entry[0].dns_name)
    sg   = local.is_management_env ? aws_security_group.internet_proxy_endpoint[0].id : aws_security_group.lower_internet_proxy_endpoint[0].id
    host = local.is_management_env ? aws_vpc_endpoint.internet_proxy[0].dns_entry[0].dns_name : aws_vpc_endpoint.lower_internet_proxy[0].dns_entry[0].dns_name
    port = 3128
  }
}


resource "null_resource" "dummy" {}

resource "null_resource" "dummy_2" {}
