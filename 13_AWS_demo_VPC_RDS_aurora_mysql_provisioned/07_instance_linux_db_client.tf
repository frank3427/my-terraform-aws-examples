# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo13_db_client {
  instance = aws_instance.demo13_db_client.id
  domain   = "vpc"
  tags     = { Name = "demo13-mysql-client" }
}

# ------ Create an EC2 instance for mysql Instance Client
resource aws_instance demo13_db_client {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.db_client_az}"
  instance_type          = var.db_client_inst_type
  ami                    = data.aws_ami.al2023_x64.id
  key_name               = aws_key_pair.demo13.id
  subnet_id              = aws_subnet.demo13_db_client.id
  vpc_security_group_ids = [ aws_default_security_group.demo13_ec2.id ] 
  tags                   = { Name = "demo13-mysql-client" }
  user_data_base64       = base64encode(templatefile(var.db_client_cloud_init_script, {
                              param_hostname = aws_rds_cluster.demo13.endpoint,
                              param_user     = var.aurora_mysql_username
  }))
                              # param_hostname = trimsuffix(aws_db_instance.demo13_mysql.endpoint,":3306"),
                              # param_user     = aws_db_instance.demo13_mysql.username
  private_ip             = var.db_client_private_ip   # optional        
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo13-boot" }
  }
}

# ------ Customize the default security group for the EC2 instance
resource aws_default_security_group demo13_ec2 {
  vpc_id      = aws_vpc.demo13.id
  tags        = { Name = "demo13-ec2-sg" }

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