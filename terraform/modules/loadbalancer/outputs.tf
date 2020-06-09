output "outputs" {
  value = {
    fqdn              = aws_route53_record.prometheus.fqdn
    security_group_id = aws_security_group.lb.id
    lb_listener       = aws_lb_listener.https.arn
  }
}
