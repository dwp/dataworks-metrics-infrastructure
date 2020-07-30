resource "aws_lb" "monitoring" {
  count              = local.is_management_env ? 1 : 0
  name               = "${var.name}-${var.primary}"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public.*.id
  security_groups    = [aws_security_group.monitoring[0].id]
  tags               = merge(local.tags, { Name = "${var.name}-lb" })
}

module "waf" {
  source                = "./modules/waf"
  name                  = var.name
  whitelist_cidr_blocks = var.whitelist_cidr_blocks
  log_bucket            = data.terraform_remote_state.security-tools.outputs.logstore_bucket.arn
  cloudwatch_log_group  = "/${var.name}/waf"
  tags                  = merge(local.tags, { Name = var.name })
}

resource "aws_wafregional_web_acl_association" "lb" {
  count        = local.is_management_env ? 1 : 0
  resource_arn = aws_lb.monitoring[local.primary_role_index].arn
  web_acl_id   = module.waf.wafregional_web_acl_id
}

resource "aws_lb_listener" "monitoring" {
  count             = local.is_management_env ? 1 : 0
  load_balancer_arn = aws_lb.monitoring[0].arn
  port              = var.https_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.monitoring[0].arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "FORBIDDEN"
      status_code  = "403"
    }
  }
}

resource "aws_lb_target_group" "prometheus" {
  count       = local.is_management_env ? 1 : 0
  name        = "${var.primary}-${var.name}-http"
  port        = var.prometheus_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  target_type = "ip"

  health_check {
    port    = var.prometheus_port
    path    = "/-/healthy"
    matcher = "200"
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }
  tags = merge(local.tags, { Name = "prometheus" })
}

resource "aws_lb_target_group" "thanos_query" {
  count       = local.is_management_env ? 1 : 0
  name        = "thanos-query-http"
  port        = var.prometheus_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  target_type = "ip"

  health_check {
    port    = var.prometheus_port
    path    = "/-/healthy"
    matcher = "200"
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }
  tags = merge(local.tags, { Name = "thanos-query" })
}

resource "aws_lb_target_group" "thanos_ruler" {
  count       = local.is_management_env ? 1 : 0
  name        = "thanos-ruler-http"
  port        = var.prometheus_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  target_type = "ip"

  health_check {
    port    = var.prometheus_port
    path    = "/-/healthy"
    matcher = "200"
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }
  tags = merge(local.tags, { Name = "thanos-ruler" })
}

resource "aws_lb_target_group" "grafana" {
  count       = local.is_management_env ? 1 : 0
  name        = "grafana-http"
  port        = var.grafana_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  target_type = "ip"

  health_check {
    port    = var.grafana_port
    path    = "/api/health"
    matcher = "200"
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }
  tags = merge(local.tags, { Name = "grafana" })
}

resource "aws_lb_target_group" "alertmanager" {
  count       = local.is_management_env ? 1 : 0
  name        = "alertmanager-http"
  port        = var.alertmanager_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  target_type = "ip"

  health_check {
    port    = var.alertmanager_port
    path    = "/-/healthy"
    matcher = "200"
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }
  tags = merge(local.tags, { Name = "alertmanager" })
}

resource "aws_lb_target_group" "outofband" {
  count       = local.is_management_env ? 1 : 0
  name        = "outofband-http"
  port        = var.prometheus_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  target_type = "ip"

  health_check {
    port    = var.prometheus_port
    path    = "/-/healthy"
    matcher = "200"
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }
  tags = merge(local.tags, { Name = "outofband" })
}

resource "aws_lb_listener_rule" "prometheus" {
  count        = local.is_management_env ? 1 : 0
  listener_arn = aws_lb_listener.monitoring[local.primary_role_index].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus[local.primary_role_index].arn
  }

  condition {
    field  = "host-header"
    values = [aws_route53_record.monitoring_loadbalancer[local.primary_role_index].fqdn]
  }
}

resource "aws_lb_listener_rule" "thanos_query" {
  count        = local.is_management_env ? 1 : 0
  listener_arn = aws_lb_listener.monitoring[local.primary_role_index].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.thanos_query[local.primary_role_index].arn
  }

  condition {
    field  = "host-header"
    values = [aws_route53_record.thanos_query_loadbalancer[local.primary_role_index].fqdn]
  }
}

resource "aws_lb_listener_rule" "thanos_ruler" {
  count        = local.is_management_env ? 1 : 0
  listener_arn = aws_lb_listener.monitoring[local.primary_role_index].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.thanos_ruler[local.primary_role_index].arn
  }

  condition {
    field  = "host-header"
    values = [aws_route53_record.thanos_ruler_loadbalancer[local.primary_role_index].fqdn]
  }
}

resource "aws_lb_listener_rule" "grafana" {
  count        = local.is_management_env ? 1 : 0
  listener_arn = aws_lb_listener.monitoring[local.primary_role_index].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana[local.primary_role_index].arn
  }

  condition {
    field  = "host-header"
    values = [aws_route53_record.grafana_loadbalancer[local.primary_role_index].fqdn]
  }
}

resource "aws_lb_listener_rule" "alertmanager" {
  count        = local.is_management_env ? 1 : 0
  listener_arn = aws_lb_listener.monitoring[local.primary_role_index].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alertmanager[local.primary_role_index].arn
  }

  condition {
    field  = "host-header"
    values = [aws_route53_record.alertmanager_loadbalancer[local.primary_role_index].fqdn]
  }
}

resource "aws_lb_listener_rule" "outofband" {
  count        = local.is_management_env ? 1 : 0
  listener_arn = aws_lb_listener.monitoring[local.primary_role_index].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.outofband[local.primary_role_index].arn
  }

  condition {
    field  = "host-header"
    values = [aws_route53_record.outofband_loadbalancer[local.primary_role_index].fqdn]
  }
}

resource "aws_security_group" "monitoring" {
  count  = local.is_management_env ? 1 : 0
  vpc_id = module.vpc.outputs.vpcs[local.primary_role_index].id
  tags   = merge(local.tags, { Name = "${var.name}-lb" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_ingress_https" {
  count             = local.is_management_env ? 1 : 0
  description       = "Enable inbound connectivity from whitelisted endpoints"
  from_port         = var.https_port
  protocol          = "tcp"
  security_group_id = aws_security_group.monitoring[local.primary_role_index].id
  to_port           = var.https_port
  type              = "ingress"
  cidr_blocks       = var.whitelist_cidr_blocks
}

resource "aws_security_group_rule" "allow_egress_thanos_query" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow loadbalancer to access thanos query http endpoint"
  type                     = "egress"
  to_port                  = var.thanos_port_http
  protocol                 = "tcp"
  from_port                = var.thanos_port_http
  security_group_id        = aws_security_group.monitoring[local.primary_role_index].id
  source_security_group_id = aws_security_group.thanos_query[local.primary_role_index].id
}

resource "aws_security_group_rule" "allow_egress_thanos_ruler" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow loadbalancer to access thanos ruler http endpoint"
  type                     = "egress"
  to_port                  = var.thanos_port_http
  protocol                 = "tcp"
  from_port                = var.thanos_port_http
  security_group_id        = aws_security_group.monitoring[local.primary_role_index].id
  source_security_group_id = aws_security_group.thanos_ruler[local.primary_role_index].id
}

resource "aws_security_group_rule" "allow_egress_grafana" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow loadbalancer to access grafana user interface"
  type                     = "egress"
  to_port                  = var.grafana_port
  protocol                 = "tcp"
  from_port                = var.grafana_port
  security_group_id        = aws_security_group.monitoring[local.primary_role_index].id
  source_security_group_id = aws_security_group.grafana[local.primary_role_index].id
}

resource "aws_security_group_rule" "allow_egress_alertmanager" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow loadbalancer to access alertmanager user interface"
  type                     = "egress"
  to_port                  = var.alertmanager_port
  protocol                 = "tcp"
  from_port                = var.alertmanager_port
  security_group_id        = aws_security_group.monitoring[local.primary_role_index].id
  source_security_group_id = aws_security_group.alertmanager[local.primary_role_index].id
}

resource "aws_security_group_rule" "allow_egress_outofband" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow loadbalancer to access outofband user interface"
  type                     = "egress"
  to_port                  = var.prometheus_port
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  security_group_id        = aws_security_group.monitoring[local.primary_role_index].id
  source_security_group_id = aws_security_group.outofband[local.primary_role_index].id
}
