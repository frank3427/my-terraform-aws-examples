# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource "aws_eip" "demo13c_db_client" {
  instance = aws_instance.demo13c_db_client.id
  domain   = "vpc"
  tags     = { Name = "demo13c-mysql-client" }
}

# ------ Create an EC2 instance for mysql Instance Client
resource "aws_instance" "demo13c_db_client" {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  instance_type          = var.db_client_inst_type
  ami                    = data.aws_ami.al2023_x64.id
  key_name               = aws_key_pair.demo13c.id
  subnet_id              = aws_subnet.demo13c_db_client.id
  vpc_security_group_ids = [aws_default_security_group.demo13c_ec2.id]
  tags                   = { Name = "demo13c-mysql-client" }
  user_data_base64 = base64encode(templatefile(var.db_client_cloud_init_script, {
    param_hostname = aws_rds_cluster.demo13c.endpoint,
    param_user     = var.aurora_mysql_username
  }))
  # param_hostname = trimsuffix(aws_db_instance.demo13c_mysql.endpoint,":3306"),
  # param_user     = aws_db_instance.demo13c_mysql.username
  private_ip = var.db_client_private_ip # optional        
  root_block_device {
    encrypted   = true # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo13c-boot" }
  }
}

# ------ Customize the default security group for the EC2 instance
resource "aws_default_security_group" "demo13c_ec2" {
  vpc_id = aws_vpc.demo13c.id
  tags   = { Name = "demo13c-ec2-sg" }

}


resource "aws_vpc_security_group_ingress_rule" "demo13c_ec2_ingress_ssh_0" {
  count             = length(var.authorized_ips)
  security_group_id = aws_default_security_group.demo13c_ec2.id
  description       = "allow SSH access from authorized public IP addresses"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.authorized_ips[count.index]
  tags              = { Name = "demo13c_ec2-sgr-ingress-ssh-0" }
}

resource "aws_vpc_security_group_ingress_rule" "demo13c_ec2_ingress_all_1" {
  security_group_id = aws_default_security_group.demo13c_ec2.id
  description       = "allow all traffic from VPC"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = var.cidr_vpc
  tags              = { Name = "demo13c_ec2-sgr-ingress-all-1" }
}

resource "aws_vpc_security_group_egress_rule" "demo13c_ec2_egress_all_2" {
  security_group_id = aws_default_security_group.demo13c_ec2.id
  description       = "allow all traffic"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo13c_ec2-sgr-egress-all-2" }
}
