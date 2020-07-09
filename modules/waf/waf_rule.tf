resource "aws_wafregional_rule" "detect_admin_access" {
  name        = "detect-admin-access"
  metric_name = "detectadminaccess"
  tags        = var.tags

  predicate {
    data_id = aws_wafregional_ipset.admin_remote_ipset.id
    negated = false
    type    = "IPMatch"
  }
}

resource "aws_wafregional_rule" "detect_bad_auth_tokens" {
  name        = "detect-bad-auth-tokens"
  metric_name = "detectbadauthtokens"
  tags        = var.tags

  predicate {
    data_id = aws_wafregional_byte_match_set.match_auth_tokens.id
    negated = false
    type    = "ByteMatch"
  }
}

resource "aws_wafregional_rule" "detect_rfi_lfi_traversal" {
  name        = "detect-rfi-lfi-traversal"
  metric_name = "detectrfilfitraversal"

  predicate {
    data_id = aws_wafregional_byte_match_set.match_rfi_lfi_traversal.id
    negated = false
    type    = "ByteMatch"
  }
}

resource "aws_wafregional_rule" "detect_ssi" {
  name        = "detect-ssi"
  metric_name = "detectssi"
  tags        = var.tags

  predicate {
    data_id = aws_wafregional_byte_match_set.match_ssi.id
    negated = false
    type    = "ByteMatch"
  }
}

resource "aws_wafregional_rule" "enforce_csrf" {
  name        = "enforce-csrf"
  metric_name = "enforcecsrf"
  tags        = var.tags

  predicate {
    data_id = aws_wafregional_byte_match_set.match_csrf_method.id
    negated = false
    type    = "ByteMatch"
  }

  predicate {
    data_id = aws_wafregional_size_constraint_set.csrf_token_set.id
    negated = true
    type    = "SizeConstraint"
  }
}

resource "aws_wafregional_rule" "mitigate_sqli" {
  name        = "mitigate-sqli"
  metric_name = "mitigatesqli"
  tags        = var.tags

  # Don't do mitigate_sqli for Prometheus/Grafana is it blocks legitimate requests
  predicate {
    data_id = aws_wafregional_byte_match_set.match_admin_url.id
    negated = true
    type    = "ByteMatch"
  }

  predicate {
    data_id = aws_wafregional_sql_injection_match_set.sql_injection_match_set.id
    negated = false
    type    = "SqlInjectionMatch"
  }
}

resource "aws_wafregional_rule" "mitigate_xss" {
  name        = "mitigate-xss"
  metric_name = "mitigatexss"
  tags        = var.tags

  predicate {
    data_id = aws_wafregional_xss_match_set.xss_match_set.id
    negated = false
    type    = "XssMatch"
  }
}

resource "aws_wafregional_rule" "restrict_sizes" {
  name        = "restrict-sizes"
  metric_name = "restrictsizes"
  tags        = var.tags

  predicate {
    data_id = aws_wafregional_size_constraint_set.size_restrictions.id
    negated = false
    type    = "SizeConstraint"
  }
}

resource "aws_wafregional_rule" "non_gb" {
  name        = "non-gb"
  metric_name = "nongb"
  tags        = var.tags

  predicate {
    data_id = aws_wafregional_geo_match_set.gb.id
    negated = true
    type    = "GeoMatch"
  }
}
