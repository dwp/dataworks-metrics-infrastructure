resource "aws_security_group" "web" {
  name        = "${var.role}-${var.name}"
  description = "prometheus web access"
  vpc_id      = var.vpc.aws_vpc.id
  tags        = merge(var.tags, { Name = var.name })

  lifecycle {
    create_before_destroy = true
  }
}
