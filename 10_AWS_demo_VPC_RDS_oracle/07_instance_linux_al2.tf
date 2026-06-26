# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource "aws_eip" "demo10_al2" {
  instance = aws_instance.demo10_al2.id
  domain   = "vpc"
  tags     = { Name = "demo10-oracle-client" }
}

# ------ Create an EC2 instance for Oracle Instance Client
resource "aws_instance" "demo10_al2" {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.al2_inst_type
  ami                    = data.aws_ami.al2_x64.id
  key_name               = aws_key_pair.demo10.id
  subnet_id              = aws_subnet.demo10_public.id
  vpc_security_group_ids = [aws_default_security_group.demo10_ec2.id]
  tags                   = { Name = "demo10-oracle-client" }
  user_data_base64 = base64encode(templatefile(var.al2_cloud_init_script, {
    param_alias    = "demo10",
    param_hostname = trimsuffix(aws_db_instance.demo10_oracle.endpoint, ":1521"),
    param_sid      = var.oracle_sid,
    param_user     = aws_db_instance.demo10_oracle.username
  }))
  private_ip = var.al2_private_ip # optional        
  root_block_device {
    encrypted   = true # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo10-al2-boot" }
  }
}

# ------ Customize the default security group for the EC2 instance
resource "aws_default_security_group" "demo10_ec2" {
  vpc_id = aws_vpc.demo10.id
  tags   = { Name = "demo10-ec2-sg" }

}


resource "aws_vpc_security_group_ingress_rule" "demo10_ec2_ingress_ssh_0" {
  count             = length(var.authorized_ips)
  security_group_id = aws_default_security_group.demo10_ec2.id
  description       = "allow SSH access from authorized public IP addresses"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.authorized_ips[count.index]
  tags              = { Name = "demo10_ec2-sgr-ingress-ssh-0" }
}

resource "aws_vpc_security_group_ingress_rule" "demo10_ec2_ingress_all_1" {
  security_group_id = aws_default_security_group.demo10_ec2.id
  description       = "allow all traffic from VPC"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = var.cidr_vpc
  tags              = { Name = "demo10_ec2-sgr-ingress-all-1" }
}

resource "aws_vpc_security_group_egress_rule" "demo10_ec2_egress_all_2" {
  security_group_id = aws_default_security_group.demo10_ec2.id
  description       = "allow all traffic"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo10_ec2-sgr-egress-all-2" }
}
