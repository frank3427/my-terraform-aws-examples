# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo09_al2 {
  instance = aws_instance.demo09_al2.id
  vpc      = true
  tags     = { Name = "demo09-al2" }
}

# ------ Create an EC2 instance
resource aws_instance demo09_al2 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.el2_az}"
  instance_type          = var.al2_inst_type
  ami                    = data.aws_ami.al2_arm64.id
  key_name               = aws_key_pair.demo09.id
  subnet_id              = aws_subnet.demo09_public1.id
  vpc_security_group_ids = [ aws_default_security_group.demo09.id ] 
  tags                   = { Name = "demo09-al2" }
  private_ip             = var.al2_private_ip   # optional        
  user_data_base64       = base64encode(templatefile(var.al2_cloud_init_script, {
                              mount_point = var.efs_mount_point,
                              dns_name    = aws_efs_file_system.demo09.dns_name
  }))
  iam_instance_profile   = "AmazonSSMRoleForInstancesQuickSetup"  # needed for easy connection in Systems Manager      
}

# Note: content of user_data can be retrieved on the EC2 instance with curl http://169.254.169.254/latest/user-data
