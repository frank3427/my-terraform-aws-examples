# ---- DNS records in public DNS domain
resource aws_route53_record cr3_alb {
  provider = aws.r1
  zone_id  = var.dns_zone_id
  name     = var.dns_name_primary
  type     = "CNAME"
  ttl      = 300
  records  = [ aws_lb.cr3_r1_alb.dns_name ]
}

resource aws_route53_record cr3_dr {
  provider = aws.r1
  zone_id  = var.dns_zone_id
  name     = var.dns_name_secondary
  type     = "CNAME"
  ttl      = 300
  records  = [ aws_eip.cr3_r2_dr.public_dns ]
}

# ---- public TLS certificate for HTTPS access to ALB
resource aws_acm_certificate cr3_alb {
  provider          = aws.r1
  domain_name       = var.dns_name_primary
  validation_method = "DNS"
  tags              = { Name = "cr3-alb-cert" }

  lifecycle {
    create_before_destroy = true
  }
}

data aws_route53_zone cr3 {
  provider     = aws.r1
  name         = var.dns_domain
  private_zone = false
}

resource aws_route53_record cr3_cert {
  provider = aws.r1
  for_each = {
    for dvo in aws_acm_certificate.cr3_alb.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.cr3.zone_id
}

resource aws_acm_certificate_validation cr3 {
  provider                = aws.r1
  certificate_arn         = aws_acm_certificate.cr3_alb.arn
  validation_record_fqdns = [ for record in aws_route53_record.cr3_cert : record.fqdn ]
}
