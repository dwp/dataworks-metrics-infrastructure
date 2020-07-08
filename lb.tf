resource "aws_lb" "monitoring" {
  count              = local.is_management_env ? 1 : 0
  name               = "${var.name}-${var.primary}"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public.*.id
  security_groups    = [aws_security_group.monitoring[0].id]
  tags               = merge(local.tags, { Name = "${var.name}-lb" })
}

resource "aws_lb_listener" "grafana" {
  count             = local.is_management_env ? 1 : 0
  load_balancer_arn = aws_lb.monitoring[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.grafana[0].arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "FORBIDDEN"
      status_code  = "403"
    }
  }
}

resource "aws_lb_listener" "thanos" {
  count             = local.is_management_env ? 1 : 0
  load_balancer_arn = aws_lb.monitoring[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.thanos[0].arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "FORBIDDEN"
      status_code  = "403"
    }
  }
}

resource "aws_lb_target_group" "thanos" {
  count       = local.is_management_env ? 1 : 0
  name        = "thanos-http"
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

  tags = merge(local.tags, { Name = "thanos" })
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

resource "aws_lb_listener_rule" "thanos" {
  count        = local.is_management_env ? 1 : 0
  listener_arn = aws_lb_listener.thanos[local.primary_role_index].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.thanos[local.primary_role_index].arn
  }

  condition {
    field  = "host-header"
    values = [aws_route53_record.thanos_loadbalancer[local.primary_role_index].fqdn]
  }
}

resource "aws_lb_listener_rule" "grafana" {
  count        = local.is_management_env ? 1 : 0
  listener_arn = aws_lb_listener.grafana[local.primary_role_index].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana[local.primary_role_index].arn
  }

  condition {
    field  = "host-header"
    values = [aws_route53_record.grafana_loadbalancer[local.primary_role_index].fqdn]
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
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.monitoring[local.primary_role_index].id
  to_port           = 443
  type              = "ingress"
  cidr_blocks       = var.whitelist_cidr_blocks
}

resource "aws_security_group_rule" "allow_egress_prom" {
  count             = local.is_management_env ? 1 : 0
  type              = "egress"
  to_port           = var.prometheus_port
  protocol          = "tcp"
  from_port         = var.prometheus_port
  security_group_id = aws_security_group.monitoring[local.primary_role_index].id
  cidr_blocks       = local.cidr_block_mon_master_vpc
}

resource "aws_security_group_rule" "allow_egress_grafana" {
  count             = local.is_management_env ? 1 : 0
  type              = "egress"
  to_port           = 3000
  protocol          = "tcp"
  from_port         = 3000
  security_group_id = aws_security_group.monitoring[local.primary_role_index].id
  cidr_blocks       = local.cidr_block_mon_master_vpc
}
