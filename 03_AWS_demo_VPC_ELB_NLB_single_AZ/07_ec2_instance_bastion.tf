# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for bastion persistent across stop/start
resource aws_eip demo03_bastion {
  instance = aws_instance.demo03_bastion.id
  domain   = "vpc"
  tags     = { Name = "demo03-bastion" }
}

# ------ Create an EC2 instances for web servers
resource aws_instance demo03_bastion {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.bastion_inst_type
  ami                    = data.aws_ami.al2023_arm64.id
  key_name               = aws_key_pair.demo03_bastion.id
  subnet_id              = aws_subnet.demo03_public.id
  vpc_security_group_ids = [ aws_security_group.demo03_sg_bastion.id ]
  tags                   = { Name = "demo03-bastion" }
  user_data_base64       = base64encode(file(var.bastion_cloud_init_script))     
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo03-bastion-boot" }
  }
}

# ------ Create a security group
resource aws_security_group demo03_sg_bastion {
  name        = "demo03-sg-bastion"
  description = "Description for demo03-sg-bastion"
  vpc_id      = aws_vpc.demo03.id
  tags        = { Name = "demo03-sg-bastion" }

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
