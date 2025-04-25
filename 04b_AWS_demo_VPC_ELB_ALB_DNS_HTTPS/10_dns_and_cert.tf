data aws_route53_zone demo04b {
  name         = var.dns_domain
  private_zone = false
}

# -------- First DNS name with first certificate
resource aws_route53_record demo04b_elb {
  zone_id = var.dns_zone_id
  name    = var.dns_name
  type    = "CNAME"
  ttl     = 300
  records = [ aws_lb.demo04b_alb.dns_name ]
}

resource aws_acm_certificate demo04b {
  domain_name       = var.dns_name
  validation_method = "DNS"
  tags              = { Name = "demo04b-cert" }

  lifecycle {
    create_before_destroy = true
  }
}

resource aws_route53_record demo04b_cert {
  for_each = {
    for dvo in aws_acm_certificate.demo04b.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.demo04b.zone_id
}

resource aws_acm_certificate_validation demo04b {
  certificate_arn         = aws_acm_certificate.demo04b.arn
  validation_record_fqdns = [ for record in aws_route53_record.demo04b_cert : record.fqdn ]
}

# output demo04b_dns_validation_for_cert {
#   value = aws_acm_certificate.demo04b.domain_validation_options
# }

# -------- Second DNS name with second certificate
resource aws_route53_record demo04b2_elb {
  zone_id = var.dns_zone_id
  name    = var.dns_name2
  type    = "CNAME"
  ttl     = 300
  records = [ aws_lb.demo04b_alb.dns_name ]
}

resource aws_acm_certificate demo04b2 {
  domain_name       = var.dns_name2
  validation_method = "DNS"
  tags              = { Name = "demo04b2-cert" }

  lifecycle {
    create_before_destroy = true
  }
}

resource aws_route53_record demo04b2_cert {
  for_each = {
    for dvo in aws_acm_certificate.demo04b2.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.demo04b.zone_id
}

resource aws_acm_certificate_validation demo04b2 {
  certificate_arn         = aws_acm_certificate.demo04b2.arn
  validation_record_fqdns = [ for record in aws_route53_record.demo04b2_cert : record.fqdn ]
}