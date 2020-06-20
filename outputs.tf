output "vpcs" {
  value = module.vpc.outputs.vpcs
}

output "private_route_tables" {
  value = module.vpc.outputs.private_route_tables
}

output "master_security_group" {
  value = aws_security_group.prometheus[0]
}

resource "null_resource" "dummy" {}
