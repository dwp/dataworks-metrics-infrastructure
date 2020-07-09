## 7.
## OWASP Top 10 July 2017 A7
## Mitigate abnormal requests via size restrictions
## Enforce consistent request hygene, limit size of key elements
##
## GitHub is known to send large payloads due to push events containing
## metadata of all commits rolled up into a single push. Limit the size to
## 128k as that seems like a reasonably large limit for now.
##
## Other limits (e.g. cookies, query strings and URI length) are set to generally
## accepted sensible values

resource "aws_wafregional_size_constraint_set" "size_restrictions" {
  name = "size-restrictions"

  size_constraints {
    text_transformation = "NONE"
    comparison_operator = "GT"
    size                = "131072"

    field_to_match {
      type = "BODY"
    }
  }


  size_constraints {
    text_transformation = "NONE"
    comparison_operator = "GT"
    size                = "4093"

    field_to_match {
      type = "HEADER"
      data = "cookie"
    }
  }

  size_constraints {
    text_transformation = "NONE"
    comparison_operator = "GT"
    size                = "1024"

    field_to_match {
      type = "QUERY_STRING"
    }
  }

  size_constraints {
    text_transformation = "NONE"
    comparison_operator = "GT"
    size                = "512"

    field_to_match {
      type = "URI"
    }
  }
}

## 8.
## OWASP Top 10 July 2017 A8
## CSRF token enforcement example
## Enforce the presence of CSRF token in request header
resource "aws_wafregional_size_constraint_set" "csrf_token_set" {
  name = "match-csrf-token"

  size_constraints {
    text_transformation = "NONE"
    comparison_operator = "EQ"
    size                = "36"

    field_to_match {
      type = "HEADER"
      data = "x-csrf-token"
    }
  }
}
