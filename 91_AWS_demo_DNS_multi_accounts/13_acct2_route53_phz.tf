resource aws_route53_zone demo91_acct2 {
  # ignore change in vpcs list file after provisioning
  # to avoid removing zone association with shared VPC
  lifecycle {
    ignore_changes = [
      vpc
    ]
  }
  provider = aws.acct2
  name     = var.r53_sub_domain2
  tags     = { Name = var.r53_sub_domain2 }
  vpc {
    vpc_id = aws_vpc.demo91_acct2.id
  }
}

resource aws_route53_record demo91_acct2_host1 {
  provider = aws.acct2
  zone_id  = aws_route53_zone.demo91_acct2.zone_id
  name     = var.r53_host2_in_acct2
  type     = "A"
  ttl      = 60
  records  = [ var.acct2_inst_private_ip ]
}

resource aws_route53_vpc_association_authorization demo91_acct2 {
  provider = aws.acct2
  vpc_id   = aws_vpc.demo91_acct0.id
  zone_id  = aws_route53_zone.demo91_acct2.id
}

resource aws_route53_zone_association demo91_acct2 {
  provider = aws.acct0
  vpc_id   = aws_vpc.demo91_acct0.id
  zone_id  = aws_route53_zone.demo91_acct2.id 
}