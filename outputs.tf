output "vpcs" {
  value = module.vpc.outputs.vpcs
}

output "private_route_tables" {
  value = module.vpc.outputs.private_route_tables
}

output "thanos_security_group" {
  value = local.is_management_env ? aws_security_group.thanos_query[0].id : null_resource.dummy.id
}

output "monitoring_bucket" {
  value = {
    id  = local.is_management_env ? aws_s3_bucket.monitoring[local.primary_role_index].id : null_resource.dummy.id
    arn = local.is_management_env ? aws_s3_bucket.monitoring[local.primary_role_index].arn : null_resource.dummy.id
    key = local.is_management_env ? aws_kms_key.monitoring_bucket_cmk[local.primary_role_index].arn : null_resource.dummy.id
  }
}

output "tanium_service_endpoint" {
  value = {
    id  = aws_vpc_endpoint.tanium_service.id
    dns = aws_vpc_endpoint.tanium_service.dns_entry[0].dns_name
    sg  = aws_security_group.tanium_service_endpoint.id
  }
}

resource "null_resource" "dummy" {}

resource "null_resource" "dummy_2" {}
