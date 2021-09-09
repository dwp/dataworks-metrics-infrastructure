resource "aws_vpc_peering_connection" "internal_compute" {
  count       = local.is_management_env ? 0 : 1
  peer_vpc_id = data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.vpc.id
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  auto_accept = true
  tags        = merge(local.tags, { Name = var.name })
}

resource "aws_route" "internal_compute_prometheus_secondary" {
  count                     = local.is_management_env ? 0 : 1
  route_table_id            = data.terraform_remote_state.aws_internal_compute.outputs.hbase_emr_route_table.id
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.internal_compute[0].id
}

resource "aws_route" "prometheus_secondary_internal_compute" {
  count                     = local.is_management_env ? 0 : local.zone_count
  route_table_id            = module.vpc.outputs.private_route_tables[local.secondary_role_index][count.index]
  destination_cidr_block    = local.cidr_block_internal_compute_vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.internal_compute[0].id
}

resource "aws_route" "adg_new_prometheus_secondary" {
  count                     = local.is_management_env ? 0 : 1
  route_table_id            = data.terraform_remote_state.aws_internal_compute.outputs.route_table_ids.adg_new
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.internal_compute[0].id
}

resource "aws_route" "pdm_new_prometheus_secondary" {
  count                     = local.is_management_env ? 0 : 1
  route_table_id            = data.terraform_remote_state.aws_internal_compute.outputs.route_table_ids.pdm_new
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.internal_compute[0].id
}

resource "aws_route" "clive_prometheus_secondary" {
  count                     = local.is_management_env ? 0 : 1
  route_table_id            = data.terraform_remote_state.aws_internal_compute.outputs.route_table_ids.clive
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.internal_compute[0].id
}

resource "aws_route" "uc_feature_prometheus_secondary" {
  count                     = local.is_management_env ? 0 : 1
  route_table_id            = data.terraform_remote_state.aws_internal_compute.outputs.route_table_ids.uc_feature
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.internal_compute[0].id
}

resource "aws_route" "cyi_prometheus_secondary" {
  count                     = local.is_management_env ? 0 : 1
  route_table_id            = data.terraform_remote_state.aws_internal_compute.outputs.route_table_ids.cyi
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.internal_compute[0].id
}

resource "aws_route" "kickstart_adg_prometheus_secondary" {
  count                     = local.is_management_env ? 0 : 1
  route_table_id            = data.terraform_remote_state.aws_internal_compute.outputs.route_table_ids.kickstart_adg
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.internal_compute[0].id
}

resource "aws_route" "mongo_latest_prometheus_secondary" {
  count                     = local.is_management_env ? 0 : 1
  route_table_id            = data.terraform_remote_state.aws_internal_compute.outputs.route_table_ids.mongo_latest
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.internal_compute[0].id
}

resource "aws_route" "htme_prometheus_secondary" {
  count                     = local.is_management_env ? 0 : 1
  route_table_id            = data.terraform_remote_state.aws_internal_compute.outputs.route_table_ids.htme
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.internal_compute[0].id
}

resource "aws_route" "hdi_prometheus_secondary" {
  count                     = local.is_management_env ? 0 : 1
  route_table_id            = data.terraform_remote_state.aws_internal_compute.outputs.route_table_ids.historic_importer
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.internal_compute[0].id
}

resource "aws_security_group_rule" "internal_compute_allow_ingress_exporter" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access internal-compute metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.jmx_port
  to_port                  = var.jmx_port
  security_group_id        = data.terraform_remote_state.aws_internal_compute.outputs.emr_common_sg.id
  source_security_group_id = aws_security_group.hbase_exporter[0].id
}

resource "aws_security_group_rule" "exporter_allow_egress_internal_compute" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access internal-compute metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.jmx_port
  to_port                  = var.jmx_port
  security_group_id        = aws_security_group.hbase_exporter[0].id
  source_security_group_id = data.terraform_remote_state.aws_internal_compute.outputs.emr_common_sg.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_htme" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access HTME metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_internal_compute.outputs.htme_sg.id
}

resource "aws_security_group_rule" "htme_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access HTME metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = data.terraform_remote_state.aws_internal_compute.outputs.htme_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_historic_importer" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access HDI metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_internal_compute.outputs.historic_importer_sg.id
}

resource "aws_security_group_rule" "historic_importer_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access HDI metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = data.terraform_remote_state.aws_internal_compute.outputs.historic_importer_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}
