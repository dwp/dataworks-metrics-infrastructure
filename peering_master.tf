provider "aws" {
  version = "~> 2.57.0"
  region  = var.region
  alias   = "dmi_management"

  assume_role {
    role_arn = "arn:aws:iam::${lookup(local.account, lookup(local.slave_peerings, local.environment))}:role/${var.assume_role}"
  }
}

resource "aws_vpc_peering_connection" "master_slave" {
  count       = local.roles[0] == "master" ? 1 : 0
  peer_vpc_id = module.vpc.outputs.vpcs[1].id
  vpc_id      = module.vpc.outputs.vpcs[0].id
  auto_accept = true
  tags        = merge(local.tags, { Name = "master_slave" })
}

resource "aws_route" "slave_route_management" {
  count                     = local.roles[0] == "master" ? local.zone_count : 0
  route_table_id            = module.vpc.outputs.private_route_tables[index(local.roles, "slave")][count.index]
  destination_cidr_block    = local.cidr_block_mon_master_vpc[0]
  vpc_peering_connection_id = aws_vpc_peering_connection.master_slave[0].id
}

resource "aws_route" "slave_route_non_management" {
  count                     = local.roles[0] == "slave" ? local.zone_count : 0
  route_table_id            = module.vpc.outputs.private_route_tables[index(local.roles, "slave")][count.index]
  destination_cidr_block    = data.terraform_remote_state.management_dmi.outputs.vpcs[0].cidr_block
  vpc_peering_connection_id = data.terraform_remote_state.management_dmi.outputs.peering_master_slave
}

resource "aws_route" "master_route_management" {
  count                     = local.roles[0] == "master" ? local.zone_count : 0
  route_table_id            = module.vpc.outputs.private_route_tables[0][count.index]
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.master_slave[0].id
}

resource "aws_route" "master_route_non_management" {
  count                     = local.roles[0] == "slave" ? local.zone_count : 0
  route_table_id            = data.terraform_remote_state.management_dmi.outputs.private_route_tables[0][count.index]
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = data.terraform_remote_state.management_dmi.outputs.peering_master_slave

  provider = aws.dmi_management
}

resource "aws_security_group_rule" "allow_ingress_master" {
  description              = "Allow master nodes to reach slave node metrics endpoints"
  from_port                = 9090
  protocol                 = "tcp"
  security_group_id        = aws_security_group.web[index(local.roles, "slave")].id
  to_port                  = 9090
  type                     = "ingress"
  source_security_group_id = local.roles[0] == "master" ? aws_security_group.web[0].id : data.terraform_remote_state.management_dmi.outputs.master_security_group.id
}

resource "aws_security_group_rule" "allow_egress_master" {
  description       = "Allow master nodes to reach slave node metrics endpoints"
  type              = "egress"
  to_port           = 9090
  protocol          = "tcp"
  from_port         = 9090
  security_group_id = local.roles[0] == "master" ? aws_security_group.web[0].id : data.terraform_remote_state.management_dmi.outputs.master_security_group.id
  cidr_blocks       = [local.cidr_block[local.environment].mon-slave-vpc]

  provider = aws.dmi_management
}
