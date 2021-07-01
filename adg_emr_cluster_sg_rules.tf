resource "aws_security_group_rule" "adg_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access adg metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  to_port                  = var.prometheus_port
  security_group_id        = data.terraform_remote_state.aws_analytical_dataset_generation.outputs.adg_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_adg" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access adg metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  to_port                  = var.prometheus_port
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_analytical_dataset_generation.outputs.adg_common_sg.id
}

resource "aws_security_group_rule" "adg_node_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access adg node metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = data.terraform_remote_state.aws_analytical_dataset_generation.outputs.adg_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_adg_node" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access adg node metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_analytical_dataset_generation.outputs.adg_common_sg.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_adg_jmx_namenode" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access adg jmx metrics on namenode"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 7101
  to_port                  = 7101
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_analytical_dataset_generation.outputs.adg_common_sg.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_adg_jmx_datanode" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access adg jmx metrics on datanode"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 7103
  to_port                  = 7103
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_analytical_dataset_generation.outputs.adg_common_sg.id
}

resource "aws_security_group_rule" "adg_namenode_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access adg namenode metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7101
  to_port                  = 7101
  security_group_id        = data.terraform_remote_state.aws_analytical_dataset_generation.outputs.adg_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "adg_datanode_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access adg datanode metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7103
  to_port                  = 7103
  security_group_id        = data.terraform_remote_state.aws_analytical_dataset_generation.outputs.adg_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "adg_resoucre_manager_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access adg yarn resource manager metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7105
  to_port                  = 7105
  security_group_id        = data.terraform_remote_state.aws_analytical_dataset_generation.outputs.adg_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "adg_node_manager_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access adg yarn node manager metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7107
  to_port                  = 7107
  security_group_id        = data.terraform_remote_state.aws_analytical_dataset_generation.outputs.adg_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_adg_resoucre_manager" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access adg yarn resource manager metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 7105
  to_port                  = 7105
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_analytical_dataset_generation.outputs.adg_common_sg.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_adg_node_manager" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access adg yarn resource manager metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 7107
  to_port                  = 7107
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_analytical_dataset_generation.outputs.adg_common_sg.id
}
