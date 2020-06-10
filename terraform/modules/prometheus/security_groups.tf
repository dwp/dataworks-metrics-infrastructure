resource "aws_security_group" "web" {
  name        = "${var.role}-${var.name}"
  description = "prometheus web access"
  vpc_id      = var.vpc.aws_vpc.id
  tags        = merge(var.tags, { Name = var.name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_ingress_prom" {
  type                     = "ingress"
  to_port                  = 9090
  protocol                 = "tcp"
  from_port                = 9090
  security_group_id        = aws_security_group.web.id
  source_security_group_id = var.lb_security_group_id
}

resource "aws_security_group_rule" "allow_egress_prom" {
  type              = "egress"
  to_port           = 9090
  protocol          = "tcp"
  from_port         = 9090
  security_group_id = aws_security_group.web.id
  cidr_blocks       = ["0.0.0.0/0"]
}
