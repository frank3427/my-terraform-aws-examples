# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo91_acct2_inst1 {
  provider   = aws.acct2
  instance = aws_instance.demo91_acct2_inst1.id
  vpc      = true
  tags     = { Name = "demo91-acct2-inst1" }
}

# ------ Create an EC2 instance
resource aws_instance demo91_acct2_inst1 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  provider               = aws.acct2
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.inst_type
  ami                    = data.aws_ami.al2_x86_64_acct2.id
  key_name               = aws_key_pair.demo91_acct2.id
  subnet_id              = aws_subnet.demo91_acct2_public.id
  vpc_security_group_ids = [ aws_default_security_group.demo91_acct2.id ] 
  tags                   = { Name = "demo91-acct2-inst1" }
  user_data_base64       = base64encode(file(var.cloud_init_script)) 
  private_ip             = var.acct2_inst_private_ip   
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { Name = "demo91-acct2-inst1-boot" }
  } 
}

# ------ Display the complete ssh command needed to connect to the instance
output Instance-acct2 {
  value = <<EOF


---- You can test DSN resolution from AWS account #2 (acct2) using following commands:
ssh -i ${var.private_sshkey_path} ec2-user@${aws_eip.demo91_acct2_inst1.public_ip}
nslookup ${var.r53_host1_in_acct1}

EOF
}