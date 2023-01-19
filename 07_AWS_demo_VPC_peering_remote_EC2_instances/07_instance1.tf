# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo07_r1 {
  provider       = aws.r1
  instance = aws_instance.demo07_r1.id
  vpc      = true
  tags     = { Name = "demo07-r1" }
}

# ------ Create an EC2 instance
resource aws_instance demo07_r1 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  provider       = aws.r1
  availability_zone      = "${var.aws_region1}${var.az}"
  instance_type          = var.inst_type
  ami                    = data.aws_ami.al2_arm64_r1.id
  key_name               = aws_key_pair.demo07_kp_r1.id
  subnet_id              = aws_subnet.demo07_public_r1.id
  vpc_security_group_ids = [ aws_security_group.demo07_sg_r1.id ] 
  tags                   = { Name = "demo07-r1" }
  user_data_base64       = base64encode(file(var.cloud_init_script))         
  iam_instance_profile   = "AmazonSSMRoleForInstancesQuickSetup"  # needed for easy connection in Systems Manager      
}