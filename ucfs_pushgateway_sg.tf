resource "aws_security_group_rule" "allow_ucfs_claimant_api_pushgateway_egress_https" {
  count             = local.is_management_env ? 0 : 1
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  security_group_id = data.terraform_remote_state.ucfs-claimant.outputs.vpce_security_groups.ucfs_claimant_api_pushgateway.id
  prefix_list_ids   = [data.terraform_remote_state.ucfs-claimant.outputs.ucfs_claimant_api_vpc.prefix_list_ids.s3]
}

resource "aws_security_group_rule" "allow_prometheus_ingress_ucfs_claimant_api_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows prometheus to access ucfs pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = data.terraform_remote_state.ucfs-claimant.outputs.vpce_security_groups.ucfs_claimant_api_pushgateway.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "allow_prometheus_egress_ucfs_claimant_api_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows prometheus to access ucfs claimant api pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.ucfs-claimant.outputs.vpce_security_groups.ucfs_claimant_api_pushgateway.id
}

resource "aws_security_group_rule" "allow_ucfs_claimant_ingress_ucfs_claimant_api_pushgateway" {
  count             = local.is_management_env ? 0 : 1
  description       = "Allows ucfs claimant ireland vpc to access ucfs pushgateway"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.pushgateway_port
  to_port           = var.pushgateway_port
  security_group_id = data.terraform_remote_state.ucfs-claimant.outputs.vpce_security_groups.ucfs_claimant_api_pushgateway.id
  cidr_blocks       = [data.terraform_remote_state.ucfs-claimant.outputs.ucfs_claimant_vpc.cidr_block]
}

resource "aws_security_group_rule" "allow_get_award_details_london_lambda_ingress_cfs_claimant_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows Snapshot Sender get award details London lambda to access ucfs claimant pushgateway"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = data.terraform_remote_state.ucfs-claimant.outputs.vpce_security_groups.ucfs_claimant_api_pushgateway.id
  source_security_group_id = data.terraform_remote_state.ucfs-claimant.outputs.security_groups.ucfs_claimant_lambda_london
}

resource "aws_security_group_rule" "allow_get_award_details_london_lambda_egress_ucfs_claimant_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows Snapshot Sender get award details London lambda to access ucfs claimant pushgateway"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.pushgateway_port
  to_port                  = var.pushgateway_port
  security_group_id        = data.terraform_remote_state.ucfs-claimant.outputs.security_groups.ucfs_claimant_lambda_london
  source_security_group_id = data.terraform_remote_state.ucfs-claimant.outputs.vpce_security_groups.ucfs_claimant_api_pushgateway.id
}
