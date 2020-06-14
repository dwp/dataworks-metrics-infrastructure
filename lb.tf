resource "aws_lb" "lb" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.lb.id]
  tags               = merge(local.tags, { Name = "${var.name}-lb" })
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.prometheus.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "FORBIDDEN"
      status_code  = "403"
    }
  }
}

resource "aws_route53_record" "prometheus" {
  name    = local.fqdn
  type    = "A"
  zone_id = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id

  alias {
    evaluate_target_health = false
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
  }

  provider = aws.management_dns
}

resource "aws_acm_certificate" "prometheus" {
  domain_name       = local.fqdn
  validation_method = "DNS"
}

resource "aws_route53_record" "prometheus_validation" {
  name    = aws_acm_certificate.prometheus.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.prometheus.domain_validation_options.0.resource_record_type
  zone_id = data.terraform_remote_state.management_dns.outputs.dataworks_zone.id
  records = [aws_acm_certificate.prometheus.domain_validation_options.0.resource_record_value]
  ttl     = 60

  provider = aws.management_dns
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.prometheus.arn
  validation_record_fqdns = [aws_route53_record.prometheus_validation.fqdn]
}

locals {
  fqdn = join(".", [var.name, local.parent_domain_name[local.environment]])
}

provider "aws" {
  version = "~> 2.57.0"
  region  = var.region
  alias   = "management_dns"

  assume_role {
    role_arn = "arn:aws:iam::${local.account["management"]}:role/${var.assume_role}"
  }
}

resource "aws_security_group" "lb" {
  vpc_id = module.vpc.vpc.id
  tags   = merge(local.tags, { Name = "${var.name}-lb" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "lb_external_https_in" {
  description       = "enable inbound connectivity from whitelisted endpoints"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.lb.id
  to_port           = 443
  type              = "ingress"
  cidr_blocks       = var.whitelist_cidr_blocks
}

resource "aws_security_group_rule" "allow_egress_prom" {
  type              = "egress"
  to_port           = 9090
  protocol          = "tcp"
  from_port         = 9090
  security_group_id = aws_security_group.lb.id
  cidr_blocks       = ["0.0.0.0/0"]
}
