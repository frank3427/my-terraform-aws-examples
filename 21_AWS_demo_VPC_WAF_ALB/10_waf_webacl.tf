# -------- Create a WebACL in WAF
resource aws_wafv2_web_acl demo21 {
  name        = "demo21_webacl"
  description = "demo21: WebACL created by Terraform"
  scope       = "REGIONAL"

  # by default, block all requests
  default_action {
    block {}
  }

  # allow requests originated from FRANCE or GERMANY
  rule {
    name     = "rule1_allow_from_france_and_germany"
    priority = 1

    action {
      allow {}
    }

    statement {
      geo_match_statement {
        country_codes = ["FR", "DE"]
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "demo21_waf_metric_rule1"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "demo21_waf_metric"
    sampled_requests_enabled   = false
  }
}

# -------- Associate the WAF WebACL with Application Load Balancer
resource aws_wafv2_web_acl_association demo21 {
  resource_arn = aws_lb.demo21_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.demo21.arn
}