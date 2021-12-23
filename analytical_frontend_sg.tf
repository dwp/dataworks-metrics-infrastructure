resource "aws_security_group_rule" "allow_prometheus_ingress_analytical_frontend" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allows prometheus to access analytical frontend service"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = data.terraform_remote_state.analytical-frontend-service.outputs.frontend_service.service_port
  to_port                  = data.terraform_remote_state.analytical-frontend-service.outputs.frontend_service.service_port
  security_group_id        = data.terraform_remote_state.analytical-frontend-service.outputs.frontend_service.sg_id
  source_security_group_id = aws_security_group.prometheus.id
}
