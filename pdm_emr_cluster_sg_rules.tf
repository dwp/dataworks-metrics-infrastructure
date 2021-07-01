resource "aws_security_group_rule" "prometheus_allow_egress_pdm_node_manager" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access pdm yarn resource manager metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 7107
  to_port                  = 7107
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_pdm_dataset_generation.outputs.pdm_common_sg.id
}

resource "aws_security_group_rule" "pdm_node_manager_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access pdm yarn node manager metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7107
  to_port                  = 7107
  security_group_id        = data.terraform_remote_state.aws_pdm_dataset_generation.outputs.pdm_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "pdm_node_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access pdm node metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = data.terraform_remote_state.aws_pdm_dataset_generation.outputs.pdm_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_pdm_node" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access pdm node metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_pdm_dataset_generation.outputs.pdm_common_sg.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_pdm_resoucre_manager" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access pdm yarn resource manager metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 7105
  to_port                  = 7105
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_pdm_dataset_generation.outputs.pdm_common_sg.id
}

resource "aws_security_group_rule" "pdm_resoucre_manager_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access pdm yarn resource manager metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7105
  to_port                  = 7105
  security_group_id        = data.terraform_remote_state.aws_pdm_dataset_generation.outputs.pdm_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_pdm_jmx_datanode" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access pdm jmx metrics on datanode"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 7103
  to_port                  = 7103
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_pdm_dataset_generation.outputs.pdm_common_sg.id
}

resource "aws_security_group_rule" "pdm_datanode_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access pdm datanode metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7103
  to_port                  = 7103
  security_group_id        = data.terraform_remote_state.aws_pdm_dataset_generation.outputs.pdm_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_pdm_jmx_namenode" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access pdm jmx metrics on namenode"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 7101
  to_port                  = 7101
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_pdm_dataset_generation.outputs.pdm_common_sg.id
}

resource "aws_security_group_rule" "pdm_namenode_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access pdm namenode metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7101
  to_port                  = 7101
  security_group_id        = data.terraform_remote_state.aws_pdm_dataset_generation.outputs.pdm_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "pdm_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access pdm metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  to_port                  = var.prometheus_port
  security_group_id        = data.terraform_remote_state.aws_pdm_dataset_generation.outputs.pdm_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_pdm" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access pdm metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  to_port                  = var.prometheus_port
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_pdm_dataset_generation.outputs.pdm_common_sg.id
}
