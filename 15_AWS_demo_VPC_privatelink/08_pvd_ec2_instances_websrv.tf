# ------ Create an EC2 instances for web servers
resource aws_instance demo15_pvd_websrv {
  # wait for NAT gateway to be ready (needed by cloud-init script)
  depends_on = [
    aws_nat_gateway.demo15_pvd
  ]
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  count                  = 2
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.pvd_websrv_inst_type
  ami                    = data.aws_ami.al2_arm64.id
  key_name               = aws_key_pair.demo15_pvd_websrv.id
  subnet_id              = aws_subnet.demo15_pvd_private.id
  vpc_security_group_ids = [ aws_security_group.demo15_pvd_sg_websrv.id ]
  tags                   = { Name = "demo15-pvd-websrv${count.index + 1}" }
  user_data_base64       = base64encode(replace(file(var.pvd_websrv_cloud_init_script),"<HOSTNAME>","websrv${count.index + 1}"))        
  #iam_instance_profile   = "AmazonSSMRoleForInstancesQuickSetup"  # needed for easy connection in Systems Manager      
}

# ------ Create a security group
resource aws_security_group demo15_pvd_sg_websrv {
  name        = "demo15-pvd-sg-websrv"
  description = "Description for demo15-pvd-sg-websrv"
  vpc_id      = aws_vpc.demo15_pvd.id
  tags        = { Name = "demo15-pvd-sg-websrv" }

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
    cidr_blocks = [ var.pvd_cidr_subnet_public ]
  }

  # ingress rule: allow SSH
  ingress {
    description = "allow SSH access from public subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ var.pvd_cidr_subnet_public ]
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
