# ------ Create VPC endpoints for Session Manager
locals {
  ssm_endpoints = ["ssm", "ec2messages", "ssmmessages"]
}

resource aws_vpc_endpoint demo03c_ssm {
  count               = length(local.ssm_endpoints)
  vpc_id              = aws_vpc.demo03c.id
  service_name        = "com.amazonaws.${var.aws_region}.${local.ssm_endpoints[count.index]}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  tags                = { Name = "demo03c-${local.ssm_endpoints[count.index]}" }
  subnet_ids          = [for subnet in aws_subnet.demo03c_private : subnet.id]
  security_group_ids  = [aws_security_group.demo03c_sg_ssm_endpoints.id]
}

# ------ Security group for VPC endpoints
resource aws_security_group demo03c_sg_ssm_endpoints {
  name        = "demo03c-sg-ssm-endpoints"
  description = "Security group for Session Manager VPC endpoints"
  vpc_id      = aws_vpc.demo03c.id
  tags        = { Name = "demo03c-sg-ssm-endpoints" }

  ingress {
    description = "allow HTTPS access from VPC (required by Session Manager)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_vpc]
  }

  egress {
    description = "allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}