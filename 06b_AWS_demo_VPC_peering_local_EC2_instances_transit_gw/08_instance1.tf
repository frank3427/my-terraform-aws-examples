# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo06b_inst1 {
  instance = aws_instance.demo06b_inst1.id
  vpc      = true
  tags     = { Name = "demo06b-inst1" }
}

# ------ Create an EC2 instance
resource aws_instance demo06b_inst1 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.inst_type
  ami                    = data.aws_ami.al2_arm64.id
  key_name               = aws_key_pair.demo06b_kp.id
  subnet_id              = aws_subnet.demo06b_public1.id
  vpc_security_group_ids = [ aws_security_group.demo06b_sg1.id ] 
  tags                   = { Name = "demo06b-inst1" }
  user_data_base64       = base64encode(file(var.cloud_init_script))         
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo06b-inst1-boot" }
  }
}