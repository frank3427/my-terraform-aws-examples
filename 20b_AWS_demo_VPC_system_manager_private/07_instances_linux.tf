# ------ Create EC2 instances in private subnet
resource aws_instance demo20b {
  count    = var.nb_instances_linux
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
  subnet_id              = aws_subnet.demo20b_private.id
  vpc_security_group_ids = [ aws_default_security_group.demo20b.id ] 
  tags                   = { Name = "demo20b-linux${count.index+1}" }
  user_data_base64       = base64encode(file(var.cloud_init_script_al2)) 
  iam_instance_profile   = aws_iam_instance_profile.demo20b_ssm.id
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { Name = "demo20b-linux${count.index+1}-boot" }
  }
}