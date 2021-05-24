resource "aws_security_group" "cert_retriever" {
  name        = "cert_retriever"
  description = "Rules necesary for pulling container image and accessing other cert_retriever instances"
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  tags        = merge(local.tags, { Name = "cert_retriever" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_cert_retriever_egress_cloudwatch_exporter" {
  description              = "Allows cert_retriever to access exporter metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.cloudwatch_exporter_port
  to_port                  = var.cloudwatch_exporter_port
  security_group_id        = aws_security_group.cert_retriever.id
  source_security_group_id = aws_security_group.cloudwatch_exporter.id
}

resource "aws_security_group_rule" "allow_cert_retriever_egress_pdm_exporter" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows cert_retriever to access PDM exporter"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.json_exporter_port
  to_port                  = var.json_exporter_port
  security_group_id        = aws_security_group.cert_retriever.id
  source_security_group_id = aws_security_group.pdm_exporter[0].id
}

resource "aws_security_group_rule" "allow_cert_retriever_egress_hbase_exporter" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows cert_retriever to access Hbase exporter"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.json_exporter_port
  to_port                  = var.json_exporter_port
  security_group_id        = aws_security_group.cert_retriever.id
  source_security_group_id = aws_security_group.hbase_exporter[0].id
}
