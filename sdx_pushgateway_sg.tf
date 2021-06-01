resource "aws_security_group_rule" "allow_sdx_pushgateway_egress_https" {
  count             = local.is_management_env ? 0 : 1
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  security_group_id = data.terraform_remote_state.aws_sdx.outputs.vpce_security_groups.sdx_pushgateway_vpce_security_group.id
  prefix_list_ids   = [data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.prefix_list_ids.s3]
}

resource "aws_security_group_rule" "allow_prometheus_ingress_sdx_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows prometheus to access sdx pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = data.terraform_remote_state.aws_sdx.outputs.vpce_security_groups.sdx_pushgateway_vpce_security_group.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "allow_snapshot_sender_ingress_sdx_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows Snapshot Sender to access sdx pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = data.terraform_remote_state.aws_sdx.outputs.vpce_security_groups.sdx_pushgateway_vpce_security_group.id
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
  source_security_group_id = data.terraform_remote_state.aws_sdx.outputs.vpce_security_groups.sdx_pushgateway_vpce_security_group.id
}

resource "aws_security_group_rule" "allow_snapshot_sender_status_checker_ingress_sdx_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows Snapshot Sender Status Checker lambda to access sdx pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = data.terraform_remote_state.aws_sdx.outputs.vpce_security_groups.sdx_pushgateway_vpce_security_group.id
  source_security_group_id = data.terraform_remote_state.snapshot_sender.outputs.security_group.snapshot_sender_status_checker
}

resource "aws_security_group_rule" "allow_snapshot_sender_status_checker_egress_sdx_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows Snapshot Sender Status Checker lambda to access sdx pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = data.terraform_remote_state.snapshot_sender.outputs.security_group.snapshot_sender_status_checker
  source_security_group_id = data.terraform_remote_state.aws_sdx.outputs.vpce_security_groups.sdx_pushgateway_vpce_security_group.id
}

resource "aws_security_group_rule" "allow_prometheus_egress_sdx_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows prometheus to access SDX pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_sdx.outputs.vpce_security_groups.sdx_pushgateway_vpce_security_group.id
}
