# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip cr3_r1_bastion {
  provider = aws.r1
  instance = aws_instance.cr3_r1_bastion.id
  vpc      = true
  tags     = { Name = "cr3-r1-bastion" }
}

# ------ Create an EC2 instance
resource aws_instance cr3_r1_bastion {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  depends_on             = [ aws_efs_file_system.cr3_r1 ]
  provider               = aws.r1
  availability_zone      = "${var.aws_region1}${var.az_bastion}"
  instance_type          = var.inst_type
  ami                    = data.aws_ami.al2_arm64_r1.id
  key_name               = aws_key_pair.cr3_r1_kp[0].id
  subnet_id              = aws_subnet.cr3_r1_bastion.id
  vpc_security_group_ids = [ aws_security_group.cr3_sg_r1_bastion.id ] 
  tags                   = { Name = "cr3-r1-bastion" }
  user_data_base64       = base64encode(templatefile(var.cloud_init_script_bastion, {
                              mount_point = var.efs_mount_point,
                              dns_name    = aws_efs_file_system.cr3_r1.dns_name
                           }))        
  #iam_instance_profile   = "AmazonSSMRoleForInstancesQuickSetup"  # needed for easy connection in Systems Manager      
}

# ------ Post provisioning by remote-exec
resource null_resource cr3_bastion {

  provisioner file {
    connection {
        agent       = false
        timeout     = "10m"
        host        = aws_eip.cr3_r1_bastion.public_ip
        user        = "ec2-user"
        private_key = file(var.private_sshkey_path[0])
    }
    source      = var.web_page_zip
    destination = "/tmp/${var.web_page_zip}"
  }

  provisioner remote-exec {
    connection {
        agent       = false
        timeout     = "10m"
        host        = aws_eip.cr3_r1_bastion.public_ip
        user        = "ec2-user"
        private_key = file(var.private_sshkey_path[0])
    }
    inline = [
      "sudo cloud-init status --wait",
      "sudo unzip -d ${var.efs_mount_point}/var_www_html /tmp/${var.web_page_zip}",
      "sudo chown ec2-user:ec2-user ${var.efs_mount_point}/var_www_html/*"
    ]
  }

}

# ------ Create a security group for the Bastion EC2 instance
resource aws_security_group cr3_sg_r1_bastion {
  provider    = aws.r1
  name        = "cr3-r1-bastion-sg"
  description = "Security group for Bastion host in region 1"
  vpc_id      = aws_vpc.cr3_r1.id
  tags        = { Name = "cr3-r1-bastion-sg" }

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