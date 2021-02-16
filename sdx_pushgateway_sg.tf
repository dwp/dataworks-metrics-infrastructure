resource "aws_security_group" "sdx_pushgateway" {
  count       = local.is_management_env ? 0 : 1
  name        = "sdx-pushgateway"
  description = "Rules necesary for pulling container image"
  vpc_id      = data.terraform_remote_state.aws_sdx.outputs.vpc.vpc.vpc.id
  tags        = merge(local.tags, { Name = "sdx-pushgateway" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_sdx_pushgateway_egress_https" {
  count             = local.is_management_env ? 0 : 1
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  security_group_id = aws_security_group.sdx_pushgateway[local.primary_role_index].id
  prefix_list_ids   = [data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.prefix_list_ids.s3]
}

resource "aws_security_group_rule" "allow_prometheus_ingress_sdx_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows prometheus to access sdx pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.sdx_pushgateway[0].id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "allow_snapshot_sender_ingress_sdx_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows Snapshot Sender to access sdx pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.sdx_pushgateway[0].id
  source_security_group_id = data.terraform_remote_state.snapshot_sender.outputs.security_group.snapshot_sender
}

resource "aws_security_group_rule" "allow_snapshot_sender_egress_sdx_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows Snapshot Sender to access sdx pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = data.terraform_remote_state.snapshot_sender.outputs.security_group.snapshot_sender
  source_security_group_id = aws_security_group.sdx_pushgateway[0].id
}
