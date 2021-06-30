resource "aws_vpc_peering_connection" "ingestion" {
  count       = local.is_management_env ? 0 : 1
  peer_vpc_id = data.terraform_remote_state.aws_ingestion.outputs.ingestion_vpc.id
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  auto_accept = true
  tags        = merge(local.tags, { Name = var.name })
}

resource "aws_route" "ingest_prometheus" {
  count                     = local.is_management_env ? 0 : 1
  route_table_id            = data.terraform_remote_state.aws_ingestion.outputs.ingestion_subnets.rtb
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.ingestion[0].id
}

resource "aws_route" "prometheus_ingest" {
  count                     = local.is_management_env ? 0 : local.zone_count
  route_table_id            = module.vpc.outputs.private_route_tables[local.secondary_role_index][count.index]
  destination_cidr_block    = local.cidr_block_ingest_vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.ingestion[0].id
}

resource "aws_security_group_rule" "k2hb_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access ingest k2hb ec2 node metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = data.terraform_remote_state.aws_ingest_consumers.outputs.security_group.k2hb_common
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_k2hb" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access ingest k2hb ec2 node metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_ingest_consumers.outputs.security_group.k2hb_common
}

resource "aws_security_group_rule" "k2hb_namenode_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access k2hb namenode metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7101
  to_port                  = 7101
  security_group_id        = data.terraform_remote_state.aws_ingest_consumers.outputs.security_group.k2hb_common
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "k2hb_datanode_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access k2hb datanode metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7103
  to_port                  = 7103
  security_group_id        = data.terraform_remote_state.aws_ingest_consumers.outputs.security_group.k2hb_common
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "k2hb_resoucre_manager_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access k2hb yarn resource manager metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7105
  to_port                  = 7105
  security_group_id        = data.terraform_remote_state.aws_ingest_consumers.outputs.security_group.k2hb_common
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "k2hb_node_manager_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access k2hb yarn node manager metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7107
  to_port                  = 7107
  security_group_id        = data.terraform_remote_state.aws_ingest_consumers.outputs.security_group.k2hb_common
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "claimant_api_kafka_consumers_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access ingest claimant api kafka consumers ec2 node metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = data.terraform_remote_state.aws_ucfs_claimant_consumer.outputs.claimant_api_kafka_consumer_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_claimant_api_kafka_consumers" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access ingest claimant api kafka consumers ec2 node metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_ucfs_claimant_consumer.outputs.claimant_api_kafka_consumer_sg.id
}
