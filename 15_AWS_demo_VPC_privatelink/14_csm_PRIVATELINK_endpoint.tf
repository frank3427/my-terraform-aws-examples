# ------ Create an interface endpoint to connect to endpoint service in PROVIDER VPC
resource aws_vpc_endpoint demo15_csm {
  vpc_id              = aws_vpc.demo15_csm.id
  service_name        = aws_vpc_endpoint_service.demo15_pvd.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [ aws_subnet.demo15_csm_public.id ]
  private_dns_enabled = false

  security_group_ids = [
    aws_security_group.demo15_csm_sg_endp.id,
  ]
}

# ------ Create a security group for this endpoint
resource aws_security_group demo15_csm_sg_endp {
  name        = "demo15-csm-sg-endp"
  description = "security group for the PRIVATELINK endpoint"
  vpc_id      = aws_vpc.demo15_csm.id
  tags        = { Name = "demo15-csm-sg-endp" }

  # ingress rule: allow SSH
  ingress {
    description = "allow HTTP access from public subnet in CONSUMER VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ var.csm_cidr_subnet_public ]
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