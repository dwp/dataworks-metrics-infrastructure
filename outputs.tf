output "vpcs" {
  value = module.vpc.outputs.vpcs
}

output "private_route_tables" {
  value = module.vpc.outputs.private_route_tables
}

output "prometheus_security_group" {
  value = aws_security_group.prometheus
}

output "monitoring_bucket" {
  value = {
    id  = local.is_management_env ? aws_s3_bucket.monitoring[local.primary_role_index].id : null_resource.dummy.id
    arn = local.is_management_env ? aws_s3_bucket.monitoring[local.primary_role_index].arn : null_resource.dummy.id
  }
}

resource "null_resource" "dummy" {}
