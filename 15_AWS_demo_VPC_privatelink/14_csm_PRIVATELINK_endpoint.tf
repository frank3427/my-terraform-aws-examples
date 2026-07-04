# ------ Create an interface endpoint to connect to endpoint service in PROVIDER VPC
resource "aws_vpc_endpoint" "demo15_csm" {
  vpc_id              = aws_vpc.demo15_csm.id
  service_name        = aws_vpc_endpoint_service.demo15_pvd.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.demo15_csm_public.id]
  private_dns_enabled = false

  security_group_ids = [
    aws_security_group.demo15_csm_sg_endp.id,
  ]
}

# ------ Create a security group for this endpoint
resource "aws_security_group" "demo15_csm_sg_endp" {
  name        = "demo15-csm-sg-endp"
  description = "security group for the PRIVATELINK endpoint"
  vpc_id      = aws_vpc.demo15_csm.id
  tags        = { Name = "demo15-csm-sg-endp" }

}


resource "aws_vpc_security_group_ingress_rule" "demo15_csm_sg_endp_ingress_http_0" {
  security_group_id = aws_security_group.demo15_csm_sg_endp.id
  description       = "allow HTTP access from public subnet in CONSUMER VPC"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.csm_cidr_subnet_public
  tags              = { Name = "demo15_csm_sg_endp-sgr-ingress-http-0" }
}

resource "aws_vpc_security_group_egress_rule" "demo15_csm_sg_endp_egress_all_1" {
  security_group_id = aws_security_group.demo15_csm_sg_endp.id
  description       = "allow all traffic"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo15_csm_sg_endp-sgr-egress-all-1" }
}
