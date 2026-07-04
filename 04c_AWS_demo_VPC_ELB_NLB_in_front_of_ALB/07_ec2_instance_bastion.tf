# ------ Create a security group for bastion
resource "aws_security_group" "demo04c_sg_bastion" {
  name        = "demo04c-sg-bastion"
  description = "sg for bastion host"
  vpc_id      = aws_vpc.demo04c.id
  tags        = { Name = "demo04c-sg-bastion" }

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


resource "aws_vpc_security_group_ingress_rule" "demo04c_sg_bastion_ingress_ssh_0" {
  count             = length(var.authorized_ips)
  security_group_id = aws_security_group.demo04c_sg_bastion.id
  description       = "allow SSH from authorized IPs"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.authorized_ips[count.index]
  tags              = { Name = "demo04c_sg_bastion-sgr-ingress-ssh-0" }
}

resource "aws_vpc_security_group_egress_rule" "demo04c_sg_bastion_egress_all_1" {
  security_group_id = aws_security_group.demo04c_sg_bastion.id
  description       = "allow all traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "demo04c_sg_bastion-sgr-egress-all-1" }
}
