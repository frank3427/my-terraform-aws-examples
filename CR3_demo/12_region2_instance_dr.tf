# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip cr3_r2_dr {
  provider = aws.r2
  instance = aws_instance.cr3_r2_dr.id
  vpc      = true
  tags     = { Name = "cr3-r2-dr" }
}

# ------ Create an EC2 instance
resource aws_instance cr3_r2_dr {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  provider               = aws.r2
  availability_zone      = "${var.aws_region2}${var.az_dr}"
  instance_type          = var.inst_type
  ami                    = data.aws_ami.al2_arm64_r2.id
  key_name               = aws_key_pair.cr3_r2_kp.id
  subnet_id              = aws_subnet.cr3_public_r2.id
  private_ip             = var.priv_ip_ws_dr
  vpc_security_group_ids = [ aws_security_group.cr3_sg_r2.id ] 
  tags                   = { Name = "cr3-r2-dr" }
  user_data_base64       = base64encode(file(var.cloud_init_script_dr))         
  #iam_instance_profile   = "AmazonSSMRoleForInstancesQuickSetup"  # needed for easy connection in Systems Manager      
}

# ------ Create a security group for the DR EC2 instance
resource aws_security_group cr3_sg_r2 {
  provider    = aws.r2
  name        = "cr3-r2-sg"
  description = "Description for cr3-r2-sg"
  vpc_id      = aws_vpc.cr3_r2.id
  tags        = { Name = "cr3-r2-sg" }

  # ingress rule: allow SSH
  ingress {
    description = "allow SSH access from authorized public IP addresses and from VPC in region 1"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = concat(var.authorized_ips, [var.cidr_vpc_r1])
  }

  # ingress rule: allow HTTP
  ingress {
    description = "allow HTTP access from authorized public IP addresses"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.authorized_ips
  }

  # ingress rule: allow traffic from other VPC
  ingress {
    description = "allow traffic from other VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"    # all protocols
    cidr_blocks = [ var.cidr_vpc_r1 ]
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

# ------ Post provisioning by remote-exec
resource null_resource cr3_r2_dr {

  provisioner file {
    connection {
        agent       = false
        timeout     = "10m"
        host        = aws_eip.cr3_r2_dr.public_ip
        user        = "ec2-user"
        private_key = file(var.private_sshkey_path[2])
    }
    source      = var.web_page_zip
    destination = "/tmp/${var.web_page_zip}"
  }

  provisioner remote-exec {
    connection {
        agent       = false
        timeout     = "10m"
        host        = aws_eip.cr3_r2_dr.public_ip
        user        = "ec2-user"
        private_key = file(var.private_sshkey_path[2])
    }
    inline = [
      "sudo cloud-init status --wait",
      "sudo unzip -d /var/www/html /tmp/${var.web_page_zip}",
      "sudo chown -R ec2-user:ec2-user /var/www/html/*"
    ]
  }

}