resource "aws_security_group" "hbase_exporter" {
  count       = local.is_management_env ? 0 : 1
  name        = "hbase-exporter"
  description = "Rules necesary for pulling container image"
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  tags        = merge(local.tags, { Name = "hbase-exporter" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_prometheus_ingress_hbase_exporter" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows prometheus to access Hbase exporter"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.json_exporter_port
  to_port                  = var.json_exporter_port
  security_group_id        = aws_security_group.hbase_exporter[0].id
  source_security_group_id = aws_security_group.prometheus.id
}
