# ------ Create an EC2 instances for web servers
resource aws_instance demo19_websrv {
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
  vpc_security_group_ids = [ aws_security_group.demo19_sg_websrv.id ]
  tags                   = { Name = "demo19-websrv${count.index + 1}" }
  user_data_base64       = base64encode(replace(file(var.websrv_cloud_init_script),"<HOSTNAME>","websrv${count.index + 1}"))        
}

# ------ Create a security group
resource aws_security_group demo19_sg_websrv {
  name        = "demo19-sg-websrv"
  description = "Description for demo19-sg-websrv"
  vpc_id      = aws_vpc.demo19.id
  tags        = { Name = "demo19-sg-websrv" }

  # ingress rule: allow HTTP
  ingress {
    description = "allow HTTP access from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ var.cidr_vpc ]
  }

  # ingress rule: allow SSH from bastion host
  ingress {
    description     = "allow SSH access from bastion host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [ aws_security_group.demo19_sg_bastion.id ]
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
