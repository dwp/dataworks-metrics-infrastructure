output "vpcs" {
  value = module.vpc.outputs.vpcs
}

output "private_route_tables" {
  value = module.vpc.outputs.private_route_tables
}

output "thanos_security_group" {
  value = local.is_management_env ? aws_security_group.thanos[0].id : null_resource.dummy.id
}

output "monitoring_bucket" {
  value = {
    id  = local.is_management_env ? aws_s3_bucket.monitoring[local.primary_role_index].id : null_resource.dummy.id
    arn = local.is_management_env ? aws_s3_bucket.monitoring[local.primary_role_index].arn : null_resource.dummy.id
    key = local.is_management_env ? aws_kms_key.monitoring_bucket_cmk[local.primary_role_index].arn : null_resource.dummy.id
  }
}

resource "null_resource" "dummy" {}
