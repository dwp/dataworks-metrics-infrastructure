resource "aws_vpc_peering_connection" "ingestion" {
  count       = local.is_management_env ? 0 : 1
  peer_vpc_id = data.terraform_remote_state.aws_ingestion.outputs.ingestion_vpc.id
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  auto_accept = true
  tags        = merge(local.tags, { Name = var.name })
}

# resource "aws_route" "ingestion_prometheus_secondary" {
#   count                     = local.is_management_env ? 0 : 1
#   route_table_id            = data.terraform_remote_state.aws_ingestion.outputs.emr_route_table.id
#   destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
#   vpc_peering_connection_id = aws_vpc_peering_connection.ingestion[0].id
# }

resource "aws_route" "prometheus_secondary_ingestion" {
  count                     = local.is_management_env ? 0 : local.zone_count
  route_table_id            = module.vpc.outputs.private_route_tables[local.secondary_role_index][count.index]
  destination_cidr_block    = local.cidr_block_ingest_vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.ingestion[0].id
}

resource "aws_security_group_rule" "ingestion_allow_ingress_exporter" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access ingestion metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.jmx_port
  to_port                  = var.jmx_port
  security_group_id        = data.terraform_remote_state.aws_ingestion.outputs.emr_common_sg.id
  source_security_group_id = aws_security_group.hbase_exporter[0].id
}

resource "aws_security_group_rule" "exporter_allow_egress_ingestion" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access ingestion metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.jmx_port
  to_port                  = var.jmx_port
  security_group_id        = aws_security_group.hbase_exporter[0].id
  source_security_group_id = data.terraform_remote_state.aws_ingestion.outputs.emr_common_sg.id
}
