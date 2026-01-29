# ------ Create a security group for webservers
resource "aws_security_group" "demo04c_sg_websrv" {
  name        = "demo04c-sg-websrv"
  description = "sg for webservers"
  vpc_id      = aws_vpc.demo04c.id
  tags        = { Name = "demo04c-sg-websrv" }

  ingress {
    description     = "allow SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.demo04c_sg_bastion.id]
  }

  egress {
    description = "allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------ Create separate ingress rule for websrv from ALB
resource "aws_security_group_rule" "demo04c_sg_websrv_ingress_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.demo04c_sg_alb.id
  security_group_id        = aws_security_group.demo04c_sg_websrv.id
  description              = "allow HTTP from ALB"
}

# ------ Create webserver EC2 instances
resource "aws_instance" "demo04c_websrv" {
  count                  = 2
  ami                    = data.aws_ami.al2023_arm64.id
  instance_type          = var.websrv_inst_type
  key_name               = aws_key_pair.demo04c_kp_websrv.key_name
  vpc_security_group_ids = [aws_security_group.demo04c_sg_websrv.id]
  subnet_id              = aws_subnet.demo04c_private_websrv[count.index].id
  user_data_base64       = base64encode(replace(file(var.websrv_cloud_init_script), "<HOSTNAME>", "websrv${count.index + 1}"))
  tags                   = { Name = "demo04c-websrv${count.index + 1}" }
}
