resource "aws_lb_target_group" "web_http" {
  name     = "${var.name}-http"
  port     = 9090
  protocol = "HTTP"
  vpc_id   = var.vpc.aws_vpc.id

  health_check {
    port    = "9090"
    path    = "/"
    matcher = "200"
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  tags = merge(var.tags, { Name = var.name })
}
