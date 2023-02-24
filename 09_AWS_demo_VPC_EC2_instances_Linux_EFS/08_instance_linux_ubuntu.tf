# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo09_ubuntu {
  instance = aws_instance.demo09_ubuntu.id
  vpc      = true
  tags     = { Name = "demo09-ubuntu" }
}

# ------ Create an EC2 instance
resource aws_instance demo09_ubuntu {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.ubuntu_az}"
  instance_type          = var.ubuntu_inst_type
  ami                    = data.aws_ami.ubuntu_2204_arm64.id
  key_name               = aws_key_pair.demo09.id
  subnet_id              = aws_subnet.demo09_public2.id
  vpc_security_group_ids = [ aws_default_security_group.demo09.id ] 
  tags                   = { Name = "demo09-ubuntu" }
  private_ip             = var.ubuntu_private_ip   # optional  
  user_data_base64       = base64encode(templatefile(var.ubuntu_cloud_init_script, {
                              mount_point = var.efs_mount_point,
                              dns_name    = aws_efs_file_system.demo09.dns_name
  }))      
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo09-ubuntu-boot" }
  }
}

