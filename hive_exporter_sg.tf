resource "aws_security_group" "hive_exporter" {
  count       = local.is_management_env ? 0 : 1
  name        = "hive-exporter"
  description = "Rules necesary for pulling container image"
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  tags        = merge(local.tags, { Name = "hive-exporter" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_hive_exporter_egress_https" {
  count             = local.is_management_env ? 0 : 1
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  to_port           = var.https_port
  protocol          = "tcp"
  prefix_list_ids   = [module.vpc.outputs.s3_prefix_list_ids[local.secondary_role_index]]
  from_port         = var.https_port
  security_group_id = aws_security_group.hive_exporter[local.primary_role_index].id
}

resource "aws_security_group_rule" "allow_prometheus_ingress_hive_exporter" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows prometheus to access ADG hive_exporter"
  type                     = "ingress"
  to_port                  = var.hive_exporter_port
  protocol                 = "tcp"
  from_port                = var.hive_exporter_port
  security_group_id        = aws_security_group.hive_exporter[0].id
  source_security_group_id = aws_security_group.prometheus.id
}
