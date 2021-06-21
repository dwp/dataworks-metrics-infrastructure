resource "aws_wafregional_web_acl" "acl" {
  name        = var.name
  metric_name = var.name
  tags        = var.tags

  logging_configuration {
    log_destination = aws_kinesis_firehose_delivery_stream.extended_s3_stream.arn
  }

  default_action {
    type = "BLOCK"
  }

  rule {
    action {
      type = "BLOCK"
    }

    priority = 1
    rule_id  = aws_wafregional_rule.non_gb.id
    type     = "REGULAR"
  }

  rule {
    action {
      type = "BLOCK"
    }

    priority = 2
    rule_id  = aws_wafregional_rule.restrict_sizes.id
    type     = "REGULAR"
  }

  rule {
    action {
      type = "BLOCK"
    }

    priority = 4
    rule_id  = aws_wafregional_rule.detect_bad_auth_tokens.id
    type     = "REGULAR"
  }

  rule {
    action {
      type = "BLOCK"
    }

    priority = 5
    rule_id  = aws_wafregional_rule.mitigate_sqli.id
    type     = "REGULAR"
  }

  rule {
    action {
      type = "BLOCK"
    }

    priority = 6
    rule_id  = aws_wafregional_rule.mitigate_xss.id
    type     = "REGULAR"
  }

  rule {
    action {
      type = "BLOCK"
    }

    priority = 7
    rule_id  = aws_wafregional_rule.detect_rfi_lfi_traversal.id
    type     = "REGULAR"
  }

  rule {
    action {
      type = "BLOCK"
    }

    priority = 8
    rule_id  = aws_wafregional_rule.detect_ssi.id
    type     = "REGULAR"
  }

  rule {
    action {
      type = "ALLOW"
    }

    priority = 9
    rule_id  = aws_wafregional_rule.detect_admin_access.id
    type     = "REGULAR"
  }
}
