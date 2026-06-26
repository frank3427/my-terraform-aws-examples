# ------ Create an EC2 instances for web servers
resource "aws_instance" "demo15c_acct1_pvd_websrv" {
  # wait for NAT gateway to be ready (needed by cloud-init script)
  depends_on = [
    aws_nat_gateway.demo15c_acct1_pvd
  ]
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  provider               = aws.acct1
  count                  = length(var.acct1_azs)
  instance_type          = var.acct1_pvd_websrv_inst_type
  ami                    = data.aws_ami.acct1_al2023_arm64.id
  key_name               = aws_key_pair.demo15c_acct1_pvd_websrv.id
  subnet_id              = aws_subnet.demo15c_acct1_pvd_private[count.index].id
  vpc_security_group_ids = [aws_security_group.demo15c_acct1_pvd_sg_websrv.id]
  tags                   = { Name = "demo15c-acct1_pvd-websrv${count.index + 1}" }
  user_data_base64       = base64encode(replace(file(var.acct1_pvd_websrv_cloud_init_script), "<HOSTNAME>", "websrv${count.index + 1}"))
  root_block_device {
    encrypted   = true # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo15c-acct1_pvd-websrv${count.index + 1}-boot" }
  }
}

# ------ Create a security group
resource "aws_security_group" "demo15c_acct1_pvd_sg_websrv" {
  provider    = aws.acct1
  name        = "demo15c-acct1_pvd-sg-websrv"
  description = "Description for demo15c-acct1_pvd-sg-websrv"
  vpc_id      = aws_vpc.demo15c_acct1_pvd.id
  tags        = { Name = "demo15c-acct1_pvd-sg-websrv" }

}


resource "aws_vpc_security_group_ingress_rule" "demo15c_acct1_pvd_sg_websrv_ingress_http_0" {
  count             = length(var.authorized_ips)
  security_group_id = aws_security_group.demo15c_acct1_pvd_sg_websrv.id
  description       = "allow HTTP access from authorized public IP addresses (thru NLB)"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.authorized_ips[count.index]
  tags              = { Name = "demo15c_acct1_pvd_sg_websrv-sgr-ingress-http-0" }
}

resource "aws_vpc_security_group_ingress_rule" "demo15c_acct1_pvd_sg_websrv_ingress_http_health_1" {
  count             = length(var.acct1_pvd_cidr_subnets_public)
  security_group_id = aws_security_group.demo15c_acct1_pvd_sg_websrv.id
  description       = "allow HTTP access from VPC public subnet (needed for health checks)"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.acct1_pvd_cidr_subnets_public[count.index]
  tags              = { Name = "demo15c_acct1_pvd_sg_websrv-sgr-ingress-http_health-1" }
}

resource "aws_vpc_security_group_ingress_rule" "demo15c_acct1_pvd_sg_websrv_ingress_ssh_2" {
  count             = length(var.acct1_pvd_cidr_subnets_public)
  security_group_id = aws_security_group.demo15c_acct1_pvd_sg_websrv.id
  description       = "allow SSH access from public subnet"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.acct1_pvd_cidr_subnets_public[count.index]
  tags              = { Name = "demo15c_acct1_pvd_sg_websrv-sgr-ingress-ssh-2" }
}

resource "aws_vpc_security_group_egress_rule" "demo15c_acct1_pvd_sg_websrv_egress_all_3" {
  security_group_id = aws_security_group.demo15c_acct1_pvd_sg_websrv.id
  description       = "allow all traffic"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo15c_acct1_pvd_sg_websrv-sgr-egress-all-3" }
}
