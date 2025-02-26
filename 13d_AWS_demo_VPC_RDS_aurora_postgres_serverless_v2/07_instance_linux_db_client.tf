# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo13d_db_client {
  instance = aws_instance.demo13d_db_client.id
  domain   = "vpc"
  tags     = { Name = "demo13d-postgresql-client" }
}

# ------ Create an EC2 instance for postgresql Instance Client
resource aws_instance demo13d_db_client {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  instance_type          = var.db_client_inst_type
  ami                    = data.aws_ami.al2023_x64.id
  key_name               = aws_key_pair.demo13d.id
  subnet_id              = aws_subnet.demo13d_db_client.id
  vpc_security_group_ids = [ aws_default_security_group.demo13d_ec2.id ] 
  tags                   = { Name = "demo13d-postgresql-client" }
  user_data_base64       = base64encode(templatefile(var.db_client_cloud_init_script, {
                              param_hostname = aws_rds_cluster.demo13d.endpoint,
                              param_user     = var.aurora_postgresql_username
                              param_password = random_string.demo13d-db-passwd.result
                              param_db_name  = var.aurora_postgresql_db_name
  }))
  private_ip             = var.db_client_private_ip   # optional        
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo13d-boot" }
  }
}

# ------ Copy local SQL scripts to EC2 instance
resource null_resource copy_sql {
  provisioner "file" {
    connection {
      host        = aws_eip.demo13d_db_client.public_ip
      user        = local.username
      private_key = file(var.private_sshkey_path)
    }
    source        = "sql_scripts/"
    destination   = "/home/ec2-user"
  }
}

# ------ Customize the default security group for the EC2 instance
resource aws_default_security_group demo13d_ec2 {
  vpc_id      = aws_vpc.demo13d.id
  tags        = { Name = "demo13d-ec2-sg" }

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