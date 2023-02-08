# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for bastion persistent across stop/start
resource aws_eip demo15_csm_bastion {
  instance = aws_instance.demo15_csm_bastion.id
  vpc      = true
  tags     = { Name = "demo15-csm-bastion" }
}

# ------ Create an EC2 instances for web servers
resource aws_instance demo15_csm_bastion {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.csm_bastion_inst_type
  ami                    = data.aws_ami.al2_arm64.id
  key_name               = aws_key_pair.demo15_csm_bastion.id
  subnet_id              = aws_subnet.demo15_csm_public.id
  vpc_security_group_ids = [ aws_security_group.demo15_csm_sg_bastion.id ]
  tags                   = { Name = "demo15-csm-bastion" }
  user_data_base64       = base64encode(file(var.csm_bastion_cloud_init_script))     
  #iam_instance_profile   = "AmazonSSMRoleForInstancesQuickSetup"  # needed for easy connection in Systems Manager        
}

# ------ Create a security group
resource aws_security_group demo15_csm_sg_bastion {
  name        = "demo15-csm-sg-bastion"
  description = "Description for demo15-csm-sg-bastion"
  vpc_id      = aws_vpc.demo15_csm.id
  tags        = { Name = "demo15-csm-sg-bastion" }

  # ingress rule: allow SSH
  ingress {
    description = "allow SSH access from authorized public IP addresses"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.authorized_ips
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
