resource "aws_security_group_rule" "prometheus_allow_egress_clive_node_manager" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access clive yarn resource manager metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 7107
  to_port                  = 7107
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_clive.outputs.aws_clive_common_sg.id
}

resource "aws_security_group_rule" "clive_node_manager_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access clive yarn node manager metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7107
  to_port                  = 7107
  security_group_id        = data.terraform_remote_state.aws_clive.outputs.aws_clive_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "clive_node_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access clive node metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = data.terraform_remote_state.aws_clive.outputs.aws_clive_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_clive_node" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access clive node metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_clive.outputs.aws_clive_common_sg.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_clive_resoucre_manager" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access clive yarn resource manager metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 7105
  to_port                  = 7105
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_clive.outputs.aws_clive_common_sg.id
}

resource "aws_security_group_rule" "clive_resoucre_manager_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access clive yarn resource manager metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7105
  to_port                  = 7105
  security_group_id        = data.terraform_remote_state.aws_clive.outputs.aws_clive_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_clive_jmx_datanode" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access clive jmx metrics on datanode"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 7103
  to_port                  = 7103
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_clive.outputs.aws_clive_common_sg.id
}

resource "aws_security_group_rule" "clive_datanode_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access clive datanode metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7103
  to_port                  = 7103
  security_group_id        = data.terraform_remote_state.aws_clive.outputs.aws_clive_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_clive_jmx_namenode" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access clive jmx metrics on namenode"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 7101
  to_port                  = 7101
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_clive.outputs.aws_clive_common_sg.id
}

resource "aws_security_group_rule" "clive_namenode_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access clive namenode metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7101
  to_port                  = 7101
  security_group_id        = data.terraform_remote_state.aws_clive.outputs.aws_clive_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "clive_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access clive metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  to_port                  = var.prometheus_port
  security_group_id        = data.terraform_remote_state.aws_clive.outputs.aws_clive_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_clive" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access clive metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  to_port                  = var.prometheus_port
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_clive.outputs.aws_clive_common_sg.id
}
