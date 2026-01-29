# ------ Create WAF WebACL to block access from countries other than France
resource "aws_wafv2_web_acl" "demo04_webacl" {
  count        = var.alb_use_waf ? 1 : 0
  name        = "demo04-webacl"
  description = "WebACL to allow access only from France"
  scope       = "REGIONAL"

  default_action {
    block {}
  }

  rule {
    name     = "AllowFranceOnly"
    priority = 1

    action {
      allow {}
    }

    statement {
      geo_match_statement {
        country_codes = ["FR"]
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "AllowFranceOnly"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "demo04WebACL"
    sampled_requests_enabled   = false
  }
}

# ------ Associate WAF WebACL with ALB
resource "aws_wafv2_web_acl_association" "demo04_webacl_association" {
  count        = var.alb_use_waf ? 1 : 0
  resource_arn = aws_lb.demo04_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.demo04_webacl[0].arn
}