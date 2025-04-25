# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo07_r2 {
  provider = aws.r2
  instance = aws_instance.demo07_r2.id
  domain   = "vpc"
  tags     = { Name = "demo07-r2" }
}

# ------ Create an EC2 instance
resource aws_instance demo07_r2 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  provider       = aws.r2
  availability_zone      = "${var.aws_region2}${var.az}"
  instance_type          = var.inst_type
  ami                    = data.aws_ami.al2_arm64_r2.id
  key_name               = aws_key_pair.demo07_kp_r2.id
  subnet_id              = aws_subnet.demo07_public_r2.id
  vpc_security_group_ids = [ aws_security_group.demo07_sg_r2.id ] 
  tags                   = { Name = "demo07-r2" }
  user_data_base64       = base64encode(file(var.cloud_init_script))         
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo07-r2-boot" }
  }
}