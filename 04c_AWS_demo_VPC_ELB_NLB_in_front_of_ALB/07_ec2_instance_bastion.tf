# ------ Create a security group for bastion
resource "aws_security_group" "demo04c_sg_bastion" {
  name        = "demo04c-sg-bastion"
  description = "sg for bastion host"
  vpc_id      = aws_vpc.demo04c.id
  tags        = { Name = "demo04c-sg-bastion" }

  ingress {
    description = "allow SSH from authorized IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.authorized_ips
  }

  egress {
    description = "allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------ Create bastion EC2 instance
resource "aws_instance" "demo04c_bastion" {
  ami                    = data.aws_ami.al2023_arm64.id
  instance_type          = var.bastion_inst_type
  key_name               = aws_key_pair.demo04c_kp_bastion.key_name
  vpc_security_group_ids = [aws_security_group.demo04c_sg_bastion.id]
  subnet_id              = aws_subnet.demo04c_public_bastion.id
  user_data_base64       = base64encode(file(var.bastion_cloud_init_script))
  tags                   = { Name = "demo04c-bastion" }
}
