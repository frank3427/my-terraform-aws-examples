# ------ Create EC2 instances for web servers
resource aws_instance demo39_websrv {
  # wait for NAT gateway to be ready (needed by cloud-init script)
  depends_on = [
    aws_nat_gateway.demo39
  ]
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  count                  = var.nb_az
  instance_type          = var.websrv_inst_type
  ami                    = data.aws_ami.al2023_arm64.id
  key_name               = aws_key_pair.demo39_websrv.id
  subnet_id              = aws_subnet.demo39_private[count.index].id
  vpc_security_group_ids = [ aws_security_group.demo39_sg_websrv.id ]
  tags                   = { Name = "demo39-websrv-az-${var.az[count.index]}" }
  user_data_base64       = base64encode(replace(file(var.websrv_cloud_init_script),"<HOSTNAME>","websrv${var.az[count.index]}"))        
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo39-websrv${var.az[count.index]}-boot" }
  }
}

# ------ Create a security group
resource aws_security_group demo39_sg_websrv {
  name        = "demo39-sg-websrv"
  description = "Description for demo39-sg-websrv"
  vpc_id      = aws_vpc.demo39.id
  tags        = { Name = "demo39-sg-websrv" }

  # ingress rule: allow HTTP
  ingress {
    description = "allow HTTP access from authorized public IP addresses (thru NLB)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.authorized_ips 
  }

  # ingress rule: allow HTTP for LB health checks
  ingress {
    description = "allow HTTP access from VPC public subnet (needed for health checks)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cidr_subnet_public
  }
  
  # ingress rule: allow SSH
  ingress {
    description = "allow SSH access from public subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cidr_subnet_public
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
