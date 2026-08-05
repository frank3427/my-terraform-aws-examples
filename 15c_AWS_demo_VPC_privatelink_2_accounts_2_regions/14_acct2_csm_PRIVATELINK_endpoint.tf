# ------ Create an interface endpoint to connect to endpoint service in PROVIDER VPC
resource "terraform_data" "wait_20_seconds" {
  depends_on = [aws_vpc_endpoint_service.demo15c_pvd]
  provisioner "local-exec" {
    command = "sleep 20"
  }
}
resource "aws_vpc_endpoint" "demo15c_acct2_csm" {
  depends_on          = [terraform_data.wait_20_seconds]
  provider            = aws.acct2
  vpc_id              = aws_vpc.demo15c_acct2_csm.id
  service_name        = aws_vpc_endpoint_service.demo15c_pvd.service_name
  service_region      = var.acct1_region
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.demo15c_acct2_csm_public.id]
  private_dns_enabled = false
  security_group_ids  = [aws_security_group.demo15c_acct2_csm_sg_endp.id]
}

output "vpc_id" {
  value = aws_vpc.demo15c_acct2_csm.id
}

output "subnet_ids" {
  value = [aws_subnet.demo15c_acct2_csm_public.id]
}

output "security_group_ids" {
  value = [aws_security_group.demo15c_acct2_csm_sg_endp.id]
}

output "service_name" {
  value = aws_vpc_endpoint_service.demo15c_pvd.service_name
}

# ------ Create a security group for this endpoint
resource "aws_security_group" "demo15c_acct2_csm_sg_endp" {
  provider    = aws.acct2
  name        = "demo15c-acct2_csm-sg-endp"
  description = "security group for the PRIVATELINK endpoint"
  vpc_id      = aws_vpc.demo15c_acct2_csm.id
  tags        = { Name = "demo15c-acct2_csm-sg-endp" }

}


resource "aws_vpc_security_group_ingress_rule" "demo15c_acct2_csm_sg_endp_ingress_http_0" {
  security_group_id = aws_security_group.demo15c_acct2_csm_sg_endp.id
  description       = "allow HTTP access from public subnet in CONSUMER VPC"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.acct2_csm_cidr_subnet_public
  tags              = { Name = "demo15c_acct2_csm_sg_endp-sgr-ingress-http-0" }
}

resource "aws_vpc_security_group_egress_rule" "demo15c_acct2_csm_sg_endp_egress_all_1" {
  security_group_id = aws_security_group.demo15c_acct2_csm_sg_endp.id
  description       = "allow all traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo15c_acct2_csm_sg_endp-sgr-egress-all-1" }
}
