# ------ Create EC2 instances for web servers
resource "aws_instance" "demo03b_websrv" {
  # wait for NAT gateway to be ready (needed by cloud-init script)
  depends_on = [
    aws_nat_gateway.demo03b
  ]
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  count                  = var.nb_az
  instance_type          = var.websrv_inst_type
  ami                    = data.aws_ami.al2023_arm64.id
  key_name               = aws_key_pair.demo03b_websrv.id
  subnet_id              = aws_subnet.demo03b_private[count.index].id
  vpc_security_group_ids = [aws_security_group.demo03b_sg_websrv.id]
  tags                   = { Name = "demo03b-websrv-az-${var.az[count.index]}" }
  user_data_base64       = base64encode(replace(file(var.websrv_cloud_init_script), "<HOSTNAME>", "websrv${var.az[count.index]}"))
  root_block_device {
    encrypted   = true # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo03b-websrv${var.az[count.index]}-boot" }
  }
}

# ------ Create a security group
resource "aws_security_group" "demo03b_sg_websrv" {
  name        = "demo03b-sg-websrv"
  description = "Description for demo03b-sg-websrv"
  vpc_id      = aws_vpc.demo03b.id
  tags        = { Name = "demo03b-sg-websrv" }

}


resource "aws_vpc_security_group_ingress_rule" "demo03b_sg_websrv_ingress_http_0" {
  count             = length(var.authorized_ips)
  security_group_id = aws_security_group.demo03b_sg_websrv.id
  description       = "allow HTTP access from authorized public IP addresses (thru NLB)"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.authorized_ips[count.index]
  tags              = { Name = "demo03b_sg_websrv-sgr-ingress-http-0" }
}

resource "aws_vpc_security_group_ingress_rule" "demo03b_sg_websrv_ingress_http_health_1" {
  count             = length(var.cidr_subnet_public)
  security_group_id = aws_security_group.demo03b_sg_websrv.id
  description       = "allow HTTP access from VPC public subnet (needed for health checks)"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.cidr_subnet_public[count.index]
  tags              = { Name = "demo03b_sg_websrv-sgr-ingress-http_health-1" }
}

resource "aws_vpc_security_group_ingress_rule" "demo03b_sg_websrv_ingress_ssh_2" {
  count             = length(var.cidr_subnet_public)
  security_group_id = aws_security_group.demo03b_sg_websrv.id
  description       = "allow SSH access from public subnet"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.cidr_subnet_public[count.index]
  tags              = { Name = "demo03b_sg_websrv-sgr-ingress-ssh-2" }
}

resource "aws_vpc_security_group_egress_rule" "demo03b_sg_websrv_egress_all_3" {
  security_group_id = aws_security_group.demo03b_sg_websrv.id
  description       = "allow all traffic"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo03b_sg_websrv-sgr-egress-all-3" }
}
