resource "aws_vpc_peering_connection" "sdx" {
  count       = local.is_management_env ? 0 : 1
  peer_vpc_id = data.terraform_remote_state.aws_sdx.outputs.vpc.vpc.id
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  auto_accept = true
  tags        = merge(local.tags, { Name = var.name })
}

resource "aws_route" "sdx_prometheus" {
  count                     = local.is_management_env ? 0 : 1
  route_table_id            = data.terraform_remote_state.aws_sdx.outputs.route_table_sdx_connectivity.id
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.sdx[0].id
}

resource "aws_route" "prometheus_sdx" {
  count                     = local.is_management_env ? 0 : local.zone_count
  route_table_id            = module.vpc.outputs.private_route_tables[local.secondary_role_index][count.index]
  destination_cidr_block    = local.cidr_block[local.environment].sdx-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.sdx[0].id
}

resource "aws_security_group_rule" "sdx_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access data egress ec2 node metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = data.terraform_remote_state.dataworks-aws-data-egress.outputs.security_group.data_egress_server
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_sdx" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access data egress ec2 node metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.dataworks-aws-data-egress.outputs.security_group.data_egress_server
}

resource "aws_security_group_rule" "snapshot_sender_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access snapshot sender ec2 node metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = data.terraform_remote_state.snapshot_sender.outputs.security_group.snapshot_sender
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_snapshot_sender" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access snapshot sender ec2 node metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.snapshot_sender.outputs.security_group.snapshot_sender
}


resource "aws_security_group_rule" "sft_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access sft metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  to_port                  = var.prometheus_port
  security_group_id        = data.terraform_remote_state.dataworks-aws-data-egress.outputs.sft_agent_service.security_group
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_sft" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access sft metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  to_port                  = var.prometheus_port
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.dataworks-aws-data-egress.outputs.sft_agent_service.security_group
}

resource "aws_security_group_rule" "sft_allow_ingress_prometheus_jmx" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access adg namenode metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9996
  to_port                  = 9996
  security_group_id        = data.terraform_remote_state.dataworks-aws-data-egress.outputs.sft_agent_service.security_group
  source_security_group_id = aws_security_group.prometheus.id
}
