# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo12b_al2 {
  instance = aws_instance.demo12b_al2.id
  domain   = "vpc"
  tags     = { Name = "demo12b-postgresql-client" }
}

# ------ Create an EC2 instance for postgresql Client
resource aws_instance demo12b_al2 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.al2_inst_type
  ami                    = data.aws_ami.al2_x64.id
  key_name               = aws_key_pair.demo12b.id
  subnet_id              = aws_subnet.demo12b_public.id
  vpc_security_group_ids = [ aws_default_security_group.demo12b_ec2.id ] 
  tags                   = { Name = "demo12b-postgresql-client" }
  user_data_base64       = base64encode(templatefile(var.al2_cloud_init_script, {
                              param_hostname = trimsuffix(aws_db_instance.demo12b_postgresql.endpoint,":5432"),
                              param_db_name  = var.postgresql_db_name
                              param_user     = local.rds_username,
                              param_password = local.rds_password
  }))
  private_ip             = var.al2_private_ip   # optional        
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo12b-al2-boot" }
  }
}

# ------ Copy local SQL scripts to EC2 instance
resource null_resource copy_sql {
  provisioner "file" {
    connection {
      host        = aws_eip.demo12b_al2.public_ip
      user        = local.ec2_username
      private_key = file(var.private_sshkey_path)
    }
    source        = "sql_scripts/"
    destination   = "/home/ec2-user"
  }
}

# ------ Customize the default security group for the EC2 instance
resource aws_default_security_group demo12b_ec2 {
  vpc_id      = aws_vpc.demo12b.id
  tags        = { Name = "demo12b-ec2-sg" }

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