# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo11_al2 {
  instance = aws_instance.demo11_al2.id
  domain   = "vpc"
  tags     = { Name = "demo11-mysql-client" }
}

# ------ Create an EC2 instance for mysql Instance Client
resource aws_instance demo11_al2 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.al2_inst_type
  ami                    = data.aws_ami.al2_x64.id
  key_name               = aws_key_pair.demo11.id
  subnet_id              = aws_subnet.demo11_public.id
  vpc_security_group_ids = [ aws_default_security_group.demo11_ec2.id ] 
  tags                   = { Name = "demo11-mysql-client" }
  user_data_base64       = base64encode(templatefile(var.al2_cloud_init_script, {
                              param_hostname = trimsuffix(aws_db_instance.demo11_mysql.endpoint,":3306"),
                              param_user     = aws_db_instance.demo11_mysql.username
  }))
  private_ip             = var.al2_private_ip   # optional        
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo11-al2-boot" }
  }
}

# ------ Customize the default security group for the EC2 instance
resource aws_default_security_group demo11_ec2 {
  vpc_id      = aws_vpc.demo11.id
  tags        = { Name = "demo11-ec2-sg" }

  # ingress rule: allow SSH
  ingress {
    description = "allow SSH access from authorized public IP addresses"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.authorized_ips
  }

  # ingress rule: allow all traffic inside VPC
  ingress {
    description = "allow all traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"    # all protocols
    cidr_blocks = [ var.cidr_vpc ]
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