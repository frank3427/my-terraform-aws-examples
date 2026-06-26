# ------ Create an EC2 instances for web servers
resource "aws_instance" "demo40_websrv" {
  # wait for NAT gateway to be ready (needed by cloud-init script)
  depends_on = [
    aws_nat_gateway.demo40
  ]
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  count                  = var.websrv_nb_instances
  instance_type          = var.websrv_inst_type
  ami                    = data.aws_ami.al2_arm64.id
  key_name               = aws_key_pair.demo40_websrv.id
  subnet_id              = aws_subnet.demo40_private_websrv[count.index % 2].id
  vpc_security_group_ids = [aws_security_group.demo40_sg_websrv.id]
  tags                   = { Name = "demo40-websrv${count.index + 1}" }
  user_data_base64       = base64encode(replace(file(var.websrv_cloud_init_script), "<HOSTNAME>", "websrv${count.index + 1}"))
  root_block_device {
    encrypted   = true # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo40-websrv${count.index + 1}-boot" }
  }
}

# ------ Create a security group
resource "aws_security_group" "demo40_sg_websrv" {
  name        = "demo40-sg-websrv"
  description = "Description for demo40-sg-websrv"
  vpc_id      = aws_vpc.demo40.id
  tags        = { Name = "demo40-sg-websrv" }

  # # ingress rule: allow SSH
  # ingress {
  #   description = "allow SSH access from public subnet"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = [ var.cidr_vpc ]
  # }

}


resource "aws_vpc_security_group_ingress_rule" "demo40_sg_websrv_ingress_http_0" {
  security_group_id            = aws_security_group.demo40_sg_websrv.id
  description                  = "allow HTTP access from ALB"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.demo40_sg_alb.id
  tags                         = { Name = "demo40_sg_websrv-sgr-ingress-http-0" }
}

resource "aws_vpc_security_group_ingress_rule" "demo40_sg_websrv_ingress_ssh_1" {
  security_group_id            = aws_security_group.demo40_sg_websrv.id
  description                  = "allow SSH access from bastion host"
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.demo40_sg_bastion.id
  tags                         = { Name = "demo40_sg_websrv-sgr-ingress-ssh-1" }
}

resource "aws_vpc_security_group_egress_rule" "demo40_sg_websrv_egress_all_2" {
  security_group_id = aws_security_group.demo40_sg_websrv.id
  description       = "allow all traffic"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo40_sg_websrv-sgr-egress-all-2" }
}
