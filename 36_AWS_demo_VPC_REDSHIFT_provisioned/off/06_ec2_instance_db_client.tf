# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for db_client persistent across stop/start
resource "aws_eip" "demo36_db_client" {
  instance = aws_instance.demo36_db_client.id
  domain   = "vpc"
  tags     = { Name = "demo36-db_client" }
}

# ------ Create an EC2 instances for web servers
resource "aws_instance" "demo36_db_client" {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.db_client_inst_type
  ami                    = data.aws_ami.al2023_x86_64.id
  key_name               = aws_key_pair.demo36_db_client.id
  subnet_id              = aws_subnet.demo36_public.id
  vpc_security_group_ids = [aws_security_group.demo36_sg_db_client.id]
  tags                   = { Name = "demo36-db_client" }
  user_data_base64       = base64encode(file(var.db_client_cloud_init_script))
  root_block_device {
    encrypted   = true # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo36-db_client-boot" }
  }
}

# ------ Create a security group
resource "aws_security_group" "demo36_sg_db_client" {
  name        = "demo36-sg-db_client"
  description = "Description for demo36-sg-db_client"
  vpc_id      = aws_vpc.demo36.id
  tags        = { Name = "demo36-sg-db_client" }

}


resource "aws_vpc_security_group_ingress_rule" "demo36_sg_db_client_ingress_ssh_0" {
  count             = length(var.authorized_ips)
  security_group_id = aws_security_group.demo36_sg_db_client.id
  description       = "allow SSH access from authorized public IP addresses"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.authorized_ips[count.index]
  tags              = { Name = "demo36_sg_db_client-sgr-ingress-ssh-0" }
}

resource "aws_vpc_security_group_egress_rule" "demo36_sg_db_client_egress_all_1" {
  security_group_id = aws_security_group.demo36_sg_db_client.id
  description       = "allow all traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo36_sg_db_client-sgr-egress-all-1" }
}
