resource "aws_lb" "monitoring" {
  count              = local.is_management_env ? 1 : 0
  name               = "${var.name}-${var.primary}"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.outputs.public_subnets[0]
  security_groups    = [aws_security_group.monitoring[0].id]
  tags               = merge(local.tags, { Name = "${var.name}-lb" })
}

resource "aws_lb_listener" "monitoring" {
  count             = local.is_management_env ? 1 : 0
  load_balancer_arn = aws_lb.monitoring[0].arn
  port              = 443
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
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = module.vpc.outputs.vpcs[0].id
  target_type = "ip"

  health_check {
    port    = "9090"
    path    = "/-/healthy"
    matcher = "200"
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  tags = merge(local.tags, { Name = "prometheus" })
}

resource "aws_lb_listener_rule" "prometheus" {
  count        = local.is_management_env ? 1 : 0
  listener_arn = aws_lb_listener.monitoring[0].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus[0].arn
  }

  condition {
    field  = "host-header"
    values = [aws_route53_record.monitoring_loadbalancer[0].fqdn]
  }
}

resource "aws_security_group" "monitoring" {
  count  = local.is_management_env ? 1 : 0
  vpc_id = module.vpc.outputs.vpcs[0].id
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
  security_group_id = aws_security_group.monitoring[0].id
  to_port           = 443
  type              = "ingress"
  cidr_blocks       = var.whitelist_cidr_blocks
}

resource "aws_security_group_rule" "allow_egress_prom" {
  count             = local.is_management_env ? 1 : 0
  type              = "egress"
  to_port           = 9090
  protocol          = "tcp"
  from_port         = 9090
  security_group_id = aws_security_group.monitoring[0].id
  cidr_blocks       = local.cidr_block_mon_master_vpc
}
