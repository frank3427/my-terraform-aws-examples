# ------ Create an interface endpoint to connect to endpoint service in PROVIDER VPC
resource aws_vpc_endpoint demo15b_acct2_csm {
  provider            = aws.acct2
  vpc_id              = aws_vpc.demo15b_acct2_csm.id
  service_name        = aws_vpc_endpoint_service.demo15b_pvd.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [ aws_subnet.demo15b_acct2_csm_public.id ]
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.demo15b_acct2_csm_sg_endp.id,
  ]
}

output acc1_service_name {
  value = aws_vpc_endpoint_service.demo15b_pvd.service_name
}

# ------ Create a security group for this endpoint
resource aws_security_group demo15b_acct2_csm_sg_endp {
  provider    = aws.acct2
  name        = "demo15b-acct2_csm-sg-endp"
  description = "security group for the PRIVATELINK endpoint"
  vpc_id      = aws_vpc.demo15b_acct2_csm.id
  tags        = { Name = "demo15b-acct2_csm-sg-endp" }

  # ingress rule: allow SSH
  ingress {
    description = "allow HTTP access from public subnet in CONSUMER VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ var.acct2_csm_cidr_subnet_public ]
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