output "vpcs" {
  value = module.vpc.outputs.vpcs
}

output "private_route_tables" {
  value = module.vpc.outputs.private_route_tables
}

output "peering_master_slave" {
  value = local.roles[0] == "master" ? aws_vpc_peering_connection.master_slave[0] : null_resource.dummy
}

output "master_security_group" {
  value = aws_security_group.web[0]
}

resource "null_resource" "dummy" {}
