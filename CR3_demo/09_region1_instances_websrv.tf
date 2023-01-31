# ------ Create EC2 instances for web servers
resource aws_instance cr3_r1_websrv {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  depends_on             = [ aws_efs_file_system.cr3_r1 ]
  provider               = aws.r1
  count                  = 3
  availability_zone      = "${var.aws_region1}${local.all_az[count.index]}"
  instance_type          = var.inst_type
  ami                    = data.aws_ami.al2_arm64_r1.id
  key_name               = aws_key_pair.cr3_r1_kp[1].id
  subnet_id              = aws_subnet.cr3_private_r1[count.index].id
  private_ip             = var.priv_ip_ws[count.index]
  vpc_security_group_ids = [ aws_security_group.cr3_sg_r1_websrv.id ] 
  tags                   = { Name = "cr3-r1-websrv${count.index+1}" }
  user_data_base64       = base64encode(templatefile(var.cloud_init_script_websrv, {
                              ws_nb         = count.index + 1,
                              mount_point   = var.efs_mount_point,
                              dns_name      = aws_efs_file_system.cr3_r1.dns_name
                              dr_ssh_key    = tls_private_key.ssh-cr3[2].private_key_pem
                              dr_private_ip = var.priv_ip_ws_dr
                           }))   
  #iam_instance_profile   = "AmazonSSMRoleForInstancesQuickSetup"  # needed for easy connection in Systems Manager      
}

# ------ Create a security group for the web servers EC2 instances
resource aws_security_group cr3_sg_r1_websrv {
  provider    = aws.r1
  name        = "cr3-r1-websrv-sg"
  description = "Security group for websrv host in region 1"
  vpc_id      = aws_vpc.cr3_r1.id
  tags        = { Name = "cr3-r1-websrv-sg" }

  # ingress rule: allow SSH
  ingress {
    description = "allow SSH access from Bastion public subnet in VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ var.cidr_bastion_r1 ]
  }

  # ingress rule: allow HTTP
  ingress {
    description = "allow HTTP access from ALB public subnet in VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cidrs_alb_r1
  }

  # ingress rule: allow traffic from other VPC
  ingress {
    description = "allow traffic from other VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"    # all protocols
    cidr_blocks = [ var.cidr_public_r2 ]
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