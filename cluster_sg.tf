resource "aws_security_group" "metrics_cluster" {
  name        = "metrics_cluster"
  description = "Rules necesary for pulling container image and accessing other metrics_cluster instances"
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  tags        = merge(local.tags, { Name = "metrics_cluster" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_metrics_cluster_egress_cloudwatch_exporter" {
  description              = "Allows metrics cluster to access exporter metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.cloudwatch_exporter_port
  to_port                  = var.cloudwatch_exporter_port
  security_group_id        = aws_security_group.metrics_cluster.id
  source_security_group_id = aws_security_group.cloudwatch_exporter.id
}

resource "aws_security_group_rule" "allow_metrics_cluster_egress_adg_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows metrics cluster to access ADG pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.metrics_cluster.id
  source_security_group_id = data.terraform_remote_state.aws_internal_compute.outputs.vpce_security_groups.adg_pushgateway_vpce_security_group.id
}

resource "aws_security_group_rule" "allow_metrics_cluster_egress_sdx_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows metrics cluster to access SDX pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.metrics_cluster.id
  source_security_group_id = aws_security_group.sdx_pushgateway[0].id
}

resource "aws_security_group_rule" "allow_metrics_cluster_egress_pdm_exporter" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows metrics cluster to access PDM exporter"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.json_exporter_port
  to_port                  = var.json_exporter_port
  security_group_id        = aws_security_group.metrics_cluster.id
  source_security_group_id = aws_security_group.pdm_exporter[0].id
}

resource "aws_security_group_rule" "allow_metrics_cluster_egress_pdm_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows metrics cluster to access PDM pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.metrics_cluster.id
  source_security_group_id = data.terraform_remote_state.aws_internal_compute.outputs.vpce_security_groups.pdm_pushgateway_vpce_security_group.id
}

resource "aws_security_group_rule" "allow_metrics_cluster_egress_hbase_exporter" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows metrics cluster to access Hbase exporter"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.json_exporter_port
  to_port                  = var.json_exporter_port
  security_group_id        = aws_security_group.metrics_cluster.id
  source_security_group_id = aws_security_group.hbase_exporter[0].id
}

resource "aws_security_group_rule" "allow_metrics_cluster_egress_htme_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows metrics cluster to access HTME pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.metrics_cluster.id
  source_security_group_id = data.terraform_remote_state.aws_internal_compute.outputs.vpce_security_groups.htme_pushgateway_vpce_security_group.id
}

resource "aws_security_group_rule" "allow_metrics_cluster_egress_ingest_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows metrics cluster to access SDX pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.metrics_cluster.id
  source_security_group_id = data.terraform_remote_state.aws_ingestion.outputs.ingestion_vpc.vpce_security_groups.ingest_pushgateway_security_group.id
}

resource "aws_security_group_rule" "allow_metrics_cluster_egress_clive_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows metrics cluster to access Clive pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.metrics_cluster.id
  source_security_group_id = data.terraform_remote_state.aws_internal_compute.outputs.vpce_security_groups.clive_pushgateway_vpce_security_group.id
}

resource "aws_security_group_rule" "allow_metrics_cluster_egress_mongo_latest_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows metrics cluster to access mongo latest pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.metrics_cluster.id
  source_security_group_id = data.terraform_remote_state.aws_internal_compute.outputs.vpce_security_groups.mongo_latest_vpce_pushgateway_security_group.id
}

resource "aws_security_group" "mgmt_metrics_cluster" {
  count       = local.is_management_env ? 1 : 0
  name        = "metrics_cluster"
  description = "Rules necesary for pulling container image and accessing other metrics_cluster instances in mgmt envs"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  tags        = merge(local.tags, { Name = "metrics_cluster" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_metrics_cluster_egress_cloudwatch_exporter_mgmt" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows metrics cluster to access exporter metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.cloudwatch_exporter_port
  to_port                  = var.cloudwatch_exporter_port
  security_group_id        = aws_security_group.mgmt_metrics_cluster[0].id
  source_security_group_id = aws_security_group.cloudwatch_exporter.id
}

resource "aws_security_group_rule" "allow_metrics_cluster_egress_azkaban_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows metrics cluster to access ADG pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.metrics_cluster.id
  source_security_group_id = aws_security_group.azkaban_pushgateway[0].id
}
