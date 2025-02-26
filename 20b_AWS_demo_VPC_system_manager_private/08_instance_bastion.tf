# ------ optional: Create Elastic IP addresses
# ------           to have public IP addresses for EC2 instances persistent across stop/start
resource aws_eip demo20b_bastion {
  instance = aws_instance.demo20b_bastion.id
  domain   = "vpc"
  tags     = { Name = "demo20b-bastion" }
}

# ------ Create EC2 instance in public subnet
resource aws_instance demo20b_bastion {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.inst_type
  ami                    = data.aws_ami.al2_x86_64.id
  key_name               = aws_key_pair.demo20b.id
  subnet_id              = aws_subnet.demo20b_public.id
  vpc_security_group_ids = [ aws_default_security_group.demo20b.id ] 
  tags                   = { Name = "demo20b-bastion" }
  iam_instance_profile   = aws_iam_instance_profile.demo20b_ssm.id
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { Name = "demo20b-bastion-boot" }
  }
}
