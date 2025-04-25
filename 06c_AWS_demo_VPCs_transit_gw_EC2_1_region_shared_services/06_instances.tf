# ------ optional: Create an Elastic IP address for each EC2 instance
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo06c {
  count    = local.nb_vpcs
  instance = aws_instance.demo06c[count.index].id
  domain   = "vpc"
  tags     = { Name = "demo06c-inst${count.index+1}" }
}

# ------ Create an EC2 instance in each VPC
resource aws_instance demo06c {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  count                  = local.nb_vpcs
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.inst_type
  ami                    = data.aws_ami.al2023_arm64.id
  key_name               = aws_key_pair.demo06c_kp.id
  subnet_id              = aws_subnet.demo06c_ec2[count.index].id
  vpc_security_group_ids = [ aws_security_group.demo06c_sg_ec2[count.index].id ] 
  tags                   = { Name = "demo06c-inst${count.index+1}" }
  user_data_base64       = base64encode(file(var.cloud_init_script))         
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo06c-inst${count.index+1}-boot" }
  }
}