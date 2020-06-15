resource "aws_lb" "lb" {
  count              = length(local.roles)
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.outputs.public_subnets[count.index]
  security_groups    = [aws_security_group.lb[count.index].id]
  tags               = merge(local.tags, { Name = "${var.name}-lb" })
}

resource "aws_lb_listener" "https" {
  count             = length(local.roles)
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

resource "aws_security_group" "lb" {
  count  = length(local.roles)
  vpc_id = module.vpc.outputs.vpc_ids[count.index]
  tags   = merge(local.tags, { Name = "${var.name}-lb" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "lb_external_https_in" {
  count             = length(local.roles)
  description       = "enable inbound connectivity from whitelisted endpoints"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.lb[count.index].id
  to_port           = 443
  type              = "ingress"
  cidr_blocks       = var.whitelist_cidr_blocks
}

resource "aws_security_group_rule" "allow_egress_prom" {
  count             = length(local.roles)
  type              = "egress"
  to_port           = 9090
  protocol          = "tcp"
  from_port         = 9090
  security_group_id = aws_security_group.lb[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]
}
