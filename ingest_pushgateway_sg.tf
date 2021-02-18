resource "aws_security_group" "ingest_pushgateway" {
  count       = local.is_management_env ? 0 : 1
  name        = "ingest-pushgateway"
  description = "Rules necesary for pulling container image"
  vpc_id      = data.terraform_remote_state.aws_ingestion.outputs.vpc.vpc.vpc.id
  tags        = merge(local.tags, { Name = "ingest-pushgateway" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_ingest_pushgateway_egress_https" {
  count             = local.is_management_env ? 0 : 1
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  security_group_id = aws_security_group.ingest_pushgateway[local.primary_role_index].id
  prefix_list_ids   = [data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.prefix_list_ids.s3]
}

resource "aws_security_group_rule" "allow_prometheus_ingress_ingest_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows prometheus to access ingest pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.ingest_pushgateway[0].id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "allow_k2hb_ingress_ingest_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows K2HB to access ingest pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.ingest_pushgateway[0].id
  source_security_group_id = data.terraform_remote_state.aws_ingest-consumers.outputs.security_group.k2hb_common
}

resource "aws_security_group_rule" "allow_k2hb_egress_ingest_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows K2HB to access ingest pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = data.terraform_remote_state.aws_ingest-consumers.outputs.security_group.k2hb_common
  source_security_group_id = aws_security_group.ingest_pushgateway[0].id
}

resource "aws_security_group_rule" "allow_k2hb_ingress_claiment_api_consumers_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows claiment api consumers to access ingest pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.ingest_pushgateway[0].id
  source_security_group_id = data.terraform_remote_state.aws_ucfs_claimant_consumer.outputs.claimant_api_kafka_consumer_sg.id
}

resource "aws_security_group_rule" "allow_claiment_api_consumers_egress_ingest_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows claiment api consumers to access ingest pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = data.terraform_remote_state.aws_ucfs_claimant_consumer.outputs.claimant_api_kafka_consumer_sg.id
  source_security_group_id = aws_security_group.ingest_pushgateway[0].id
}
