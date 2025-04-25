# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for bastion persistent across stop/start
resource aws_eip demo15b_acct1_pvd_bastion {
  provider = aws.acct1
  instance = aws_instance.demo15b_acct1_pvd_bastion.id
  domain   = "vpc"
  tags     = { Name = "demo15b-acct1_pvd-bastion" }
}

# ------ Create an EC2 instances for web servers
resource aws_instance demo15b_acct1_pvd_bastion {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  provider               = aws.acct1
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.acct1_pvd_bastion_inst_type
  ami                    = data.aws_ami.acct1_al2023_arm64.id
  key_name               = aws_key_pair.demo15b_acct1_pvd_bastion.id
  subnet_id              = aws_subnet.demo15b_acct1_pvd_public.id
  vpc_security_group_ids = [ aws_security_group.demo15b_acct1_pvd_sg_bastion.id ]
  tags                   = { Name = "demo15b-acct1_pvd-bastion" }
  user_data_base64       = base64encode(file(var.acct1_pvd_bastion_cloud_init_script))     
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo15b-acct1_pvd-bastion-boot" }
  }
}

# ------ Create a security group
resource aws_security_group demo15b_acct1_pvd_sg_bastion {
  provider    = aws.acct1
  name        = "demo15b-acct1_pvd-sg-bastion"
  description = "Description for demo15b-acct1_pvd-sg-bastion"
  vpc_id      = aws_vpc.demo15b_acct1_pvd.id
  tags        = { Name = "demo15b-acct1_pvd-sg-bastion" }

  # ingress rule: allow SSH
  ingress {
    description = "allow SSH access from authorized public IP addresses"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.authorized_ips
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
