resource "aws_lb_target_group" "web_http" {
  name        = "${var.role}-${var.name}-http"
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = var.vpc.aws_vpc.id
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

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_lb_listener_rule" "https" {
  listener_arn = var.lb_listener

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_http.arn
  }

  condition {
    field  = "host-header"
    values = [var.fqdn]
  }
}
