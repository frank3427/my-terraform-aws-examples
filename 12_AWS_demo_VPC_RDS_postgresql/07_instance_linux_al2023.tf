# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource "aws_eip" "demo12_al2023" {
  instance = aws_instance.demo12_al2023.id
  domain   = "vpc"
  tags     = { Name = "demo12-postgresql-client" }
}

# ------ Create an EC2 instance for postgresql Client
resource "aws_instance" "demo12_al2023" {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.al2023_inst_type
  ami                    = data.aws_ami.al2023_x64.id
  key_name               = aws_key_pair.demo12.id
  subnet_id              = aws_subnet.demo12_public.id
  vpc_security_group_ids = [aws_default_security_group.demo12_ec2.id]
  tags                   = { Name = "demo12-postgresql-client" }
  user_data_base64 = base64encode(templatefile(var.al2023_cloud_init_script, {
    param_hostname = trimsuffix(aws_db_instance.demo12_postgresql.endpoint, ":5432"),
    param_db_name  = var.postgresql_db_name
    param_user     = aws_db_instance.demo12_postgresql.username,
    param_password = random_string.demo12-db-passwd.result
  }))
  private_ip = var.al2023_private_ip # optional        
  root_block_device {
    encrypted   = true # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo12-al2023-boot" }
  }
}

# ------ Copy local SQL scripts to EC2 instance
resource "terraform_data" "copy_sql" {
  provisioner "file" {
    connection {
      host        = aws_eip.demo12_al2023.public_ip
      user        = local.username
      private_key = file(var.private_sshkey_path)
    }
    source      = "sql_scripts/"
    destination = "/home/ec2-user"
  }
}

# ------ Customize the default security group for the EC2 instance
resource "aws_default_security_group" "demo12_ec2" {
  vpc_id = aws_vpc.demo12.id
  tags   = { Name = "demo12-ec2-sg" }

}


resource "aws_vpc_security_group_ingress_rule" "demo12_ec2_ingress_ssh_0" {
  count             = length(var.authorized_ips)
  security_group_id = aws_default_security_group.demo12_ec2.id
  description       = "allow SSH access from authorized public IP addresses"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.authorized_ips[count.index]
  tags              = { Name = "demo12_ec2-sgr-ingress-ssh-0" }
}

resource "aws_vpc_security_group_ingress_rule" "demo12_ec2_ingress_all_1" {
  security_group_id = aws_default_security_group.demo12_ec2.id
  description       = "allow all traffic from VPC"
  ip_protocol       = "-1"
  cidr_ipv4         = var.cidr_vpc
  tags              = { Name = "demo12_ec2-sgr-ingress-all-1" }
}

resource "aws_vpc_security_group_egress_rule" "demo12_ec2_egress_all_2" {
  security_group_id = aws_default_security_group.demo12_ec2.id
  description       = "allow all traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo12_ec2-sgr-egress-all-2" }
}
