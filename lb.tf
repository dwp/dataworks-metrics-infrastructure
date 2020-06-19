resource "aws_lb" "lb" {
  count              = local.roles[0] == "master" ? 1 : 0
  name               = "${var.name}-${local.roles[count.index]}"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.outputs.public_subnets[count.index]
  security_groups    = [aws_security_group.lb[count.index].id]
  tags               = merge(local.tags, { Name = "${var.name}-lb" })
}

resource "aws_lb_listener" "https" {
  count             = local.roles[0] == "master" ? 1 : 0
  load_balancer_arn = aws_lb.lb[count.index].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.prometheus[count.index].arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "FORBIDDEN"
      status_code  = "403"
    }
  }
}

resource "aws_lb_target_group" "web_http" {
  count       = local.roles[0] == "master" ? 1 : 0
  name        = "${local.roles[count.index]}-${var.name}-http"
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = module.vpc.outputs.vpcs[count.index].id
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

resource "aws_lb_listener_rule" "https" {
  count        = local.roles[0] == "master" ? 1 : 0
  listener_arn = aws_lb_listener.https[count.index].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_http[count.index].arn
  }

  condition {
    field  = "host-header"
    values = [aws_route53_record.prometheus[count.index].fqdn]
  }
}

resource "aws_security_group" "lb" {
  count  = local.roles[0] == "master" ? 1 : 0
  vpc_id = module.vpc.outputs.vpcs[count.index].id
  tags   = merge(local.tags, { Name = "${var.name}-lb" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "lb_external_https_in" {
  count             = local.roles[0] == "master" ? 1 : 0
  description       = "enable inbound connectivity from whitelisted endpoints"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.lb[count.index].id
  to_port           = 443
  type              = "ingress"
  cidr_blocks       = var.whitelist_cidr_blocks
}

resource "aws_security_group_rule" "allow_egress_prom" {
  count             = local.roles[0] == "master" ? 1 : 0
  type              = "egress"
  to_port           = 9090
  protocol          = "tcp"
  from_port         = 9090
  security_group_id = aws_security_group.lb[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]
}
