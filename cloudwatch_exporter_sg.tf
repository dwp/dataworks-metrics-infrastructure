resource "aws_security_group" "cloudwatch_exporter" {
  name        = "cloudwatch-exporter"
  description = "Rules necesary for pulling container image and accessing other thanos query instance"
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  tags        = merge(local.tags, { Name = "cloudwatch-exporter" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_prometheus_ingress_cloudwatch_exporter" {
  description              = "Allows prometheus to access exporter metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.cloudwatch_exporter_port
  to_port                  = var.cloudwatch_exporter_port
  security_group_id        = aws_security_group.cloudwatch_exporter.id
  source_security_group_id = aws_security_group.prometheus.id
}
