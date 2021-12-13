resource "aws_security_group" "prometheus" {
  name        = "prometheus"
  description = "Rules necesary for pulling container image and accessing other prometheus instances"
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  tags        = merge(local.tags, { Name = "prometheus" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_prometheus_egress_cloudwatch_exporter" {
  description              = "Allows prometheus to access exporter metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.cloudwatch_exporter_port
  to_port                  = var.cloudwatch_exporter_port
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = aws_security_group.cloudwatch_exporter.id
}

resource "aws_security_group_rule" "allow_prometheus_egress_pdm_exporter" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows prometheus to access PDM exporter"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.json_exporter_port
  to_port                  = var.json_exporter_port
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = aws_security_group.pdm_exporter[0].id
}

resource "aws_security_group_rule" "allow_prometheus_egress_hbase_exporter" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows prometheus to access Hbase exporter"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.json_exporter_port
  to_port                  = var.json_exporter_port
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = aws_security_group.hbase_exporter[0].id
}

resource "aws_security_group_rule" "allow_prometheus_egress_analytical_frontend_service" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows prometheus to access Analytical Frontend Service"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = data.terraform_remote_state.analytical-frontend-service.outputs.frontend_service.service_port
  to_port                  = data.terraform_remote_state.analytical-frontend-service.outputs.frontend_service.service_port
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.analytical-frontend-service.outputs.frontend_service.sg_id
}
