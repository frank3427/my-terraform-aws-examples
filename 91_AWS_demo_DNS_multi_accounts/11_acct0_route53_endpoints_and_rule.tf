# -------- Route53 resolver endpoint inbound
resource aws_security_group demo91_acct0_inbound {
  provider = aws.acct0
  name     = "demo91-acct0-sg-r53-endp-inb"
  vpc_id   = aws_vpc.demo91_acct0.id
  tags     = { Name = "demo91-acct0-sg-r53-endp-inb" }

  ingress {
    description = "allow DNS requests (TCP)"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    description = "allow DNS requests (UDP)"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  # egress rule: allow all traffic
  egress {
    description = "allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"    # all protocols
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource aws_route53_resolver_endpoint demo91_acct0_inbound {
  provider  = aws.acct0
  name      = "demo91-inbound"
  direction = "INBOUND"

  security_group_ids = [
    aws_security_group.demo91_acct0_inbound.id,
  ]

  ip_address {
    subnet_id = aws_subnet.demo91_acct0_public.id
    ip        = var.r53_endp_inb_ip1
  }

  ip_address {
    subnet_id = aws_subnet.demo91_acct0_public.id
    ip        = var.r53_endp_inb_ip2
  }

  tags = {
    Name = "demo91-inbound"
  }
}

# -------- Route53 resolver endpoint outbound
resource aws_security_group demo91_acct0_outbound {
  provider = aws.acct0
  name     = "demo91-acct0-sg-r53-endp-outb"
  vpc_id   = aws_vpc.demo91_acct0.id
  tags     = { Name = "demo91-acct0-sg-r53-endp-outb" }

  # egress rule: allow all traffic
  egress {
    description = "allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"    # all protocols
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource aws_route53_resolver_endpoint demo91_acct0_outbound {
  provider  = aws.acct0
  name      = "demo91-outbound"
  direction = "OUTBOUND"

  security_group_ids = [
    aws_security_group.demo91_acct0_outbound.id,
  ]

  ip_address {
    subnet_id = aws_subnet.demo91_acct0_public.id
    ip        = var.r53_endp_outb_ip1
  }

  ip_address {
    subnet_id = aws_subnet.demo91_acct0_public.id
    ip        = var.r53_endp_outb_ip2
  }

  tags = {
    Name = "demo91-outbound"
  }
}

# -------- Route53 resolver rule to inbound endpoint
resource aws_route53_resolver_rule demo91 {
  provider             = aws.acct0
  domain_name          = var.r53_domain
  name                 = "demo91-forward"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.demo91_acct0_outbound.id

  target_ip {
    ip = var.r53_endp_inb_ip1
  }

  tags = {
    Name = "demo91-rule"
  }
}

# -------- Share the Resolver rule with the 2 AWS accounts
#          Note: no need to accept the share from acct1 and acct2 accounts 
#          if they belong to same AWS org as acct0 and auto accept is enabled in the org.
resource aws_ram_resource_share demo91_acct0_resolver_rule {
  provider                  = aws.acct0
  name                      = "resolver-rule"
  allow_external_principals = false

  tags = {
    Name = "demo91-resolver-rule"
  }
}

resource aws_ram_resource_association demo91_acct0_resolver_rule {
  provider           = aws.acct0
  resource_arn       = aws_route53_resolver_rule.demo91.arn
  resource_share_arn = aws_ram_resource_share.demo91_acct0_resolver_rule.arn
}

resource aws_ram_principal_association demo91_acct0_for_acct1 {
  provider           = aws.acct0
  principal          = data.aws_caller_identity.acct1.account_id
  resource_share_arn = aws_ram_resource_share.demo91_acct0_resolver_rule.arn
}

resource aws_ram_principal_association demo91_acct0_for_acct2 {
  provider           = aws.acct0
  principal          = data.aws_caller_identity.acct2.account_id
  resource_share_arn = aws_ram_resource_share.demo91_acct0_resolver_rule.arn
}

# -------- Associate shared Resolver rule with local VPCs (wait 2 minutes after sharing the resolver rule with other accounts)
resource aws_route53_resolver_rule_association demo91_acct1 {
  depends_on       = [ aws_ram_resource_association.demo91_acct0_resolver_rule, aws_ram_principal_association.demo91_acct0_for_acct1 ]
  provider         = aws.acct1
  resolver_rule_id = aws_route53_resolver_rule.demo91.id
  vpc_id           = aws_vpc.demo91_acct1.id
}

resource aws_route53_resolver_rule_association demo91_acct2 {
  depends_on       = [ aws_ram_resource_association.demo91_acct0_resolver_rule, aws_ram_principal_association.demo91_acct0_for_acct2 ]
  provider         = aws.acct2
  resolver_rule_id = aws_route53_resolver_rule.demo91.id
  vpc_id           = aws_vpc.demo91_acct2.id
}

# resource null_resource demo91_wait_2_minutes {
#   depends_on = [ aws_ram_principal_association.demo91_acct0_for_acct1, aws_ram_principal_association.demo91_acct0_for_acct2 ]
#   provisioner "local-exec" {
#     command = "sleep 120"
#   }
# }

# resource aws_route53_resolver_rule_association demo91_acct1 {
#   depends_on       = [ null_resource.demo91_wait_2_minutes ]
#   provider         = aws.acct1
#   resolver_rule_id = aws_route53_resolver_rule.demo91.id
#   vpc_id           = aws_vpc.demo91_acct1.id
# }

# resource aws_route53_resolver_rule_association demo91_acct2 {
#   depends_on       = [ null_resource.demo91_wait_2_minutes ]
#   provider         = aws.acct2
#   resolver_rule_id = aws_route53_resolver_rule.demo91.id
#   vpc_id           = aws_vpc.demo91_acct2.id
# }