# ------ Create an EC2 instances for web servers
resource "aws_instance" "demo19_websrv" {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  count                  = 2
  instance_type          = var.websrv_inst_type
  ami                    = data.aws_ami.al2_arm64.id
  key_name               = aws_key_pair.demo19_websrv.id
  subnet_id              = aws_subnet.demo19_public.id
  private_ip             = var.websrv_private_ips[count.index]
  vpc_security_group_ids = [aws_security_group.demo19_sg_websrv.id]
  tags                   = { Name = "demo19-websrv${count.index + 1}" }
  user_data_base64       = base64encode(replace(file(var.websrv_cloud_init_script), "<HOSTNAME>", "websrv${count.index + 1}"))
  root_block_device {
    encrypted   = true # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { Name = "demo19-websrv${count.index + 1}-boot" }
  }
}

# ------ Create a security group
resource "aws_security_group" "demo19_sg_websrv" {
  name        = "demo19-sg-websrv"
  description = "Description for demo19-sg-websrv"
  vpc_id      = aws_vpc.demo19.id
  tags        = { Name = "demo19-sg-websrv" }

}


resource "aws_vpc_security_group_ingress_rule" "demo19_sg_websrv_ingress_http_0" {
  security_group_id = aws_security_group.demo19_sg_websrv.id
  description       = "allow HTTP access from VPC"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.cidr_vpc
  tags              = { Name = "demo19_sg_websrv-sgr-ingress-http-0" }
}

resource "aws_vpc_security_group_ingress_rule" "demo19_sg_websrv_ingress_ssh_1" {
  security_group_id            = aws_security_group.demo19_sg_websrv.id
  description                  = "allow SSH access from bastion host"
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.demo19_sg_bastion.id
  tags                         = { Name = "demo19_sg_websrv-sgr-ingress-ssh-1" }
}

resource "aws_vpc_security_group_egress_rule" "demo19_sg_websrv_egress_all_2" {
  security_group_id = aws_security_group.demo19_sg_websrv.id
  description       = "allow all traffic"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo19_sg_websrv-sgr-egress-all-2" }
}
