# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo16_inst1 {
  instance = aws_instance.demo16_inst1.id
  domain   = "vpc"
  tags     = { Name = "demo16-inst1" }
}

# ------ Create an EC2 instance
resource aws_instance demo16_inst1 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.inst1_type
  ami                    = local.ami
  key_name               = aws_key_pair.demo16.id
  subnet_id              = aws_subnet.demo16_public.id
  vpc_security_group_ids = [ aws_default_security_group.demo16.id ] 
  tags                   = { Name = "demo16-inst1" }
  user_data_base64       = base64encode(file(local.script)) 
  private_ip             = var.inst1_private_ip   # optional  
  iam_instance_profile   = aws_iam_instance_profile.demo16_cloudwatch.id
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo16-inst1-boot" }
  }
}

# ------ Display the complete ssh command needed to connect to the instance
locals {
  username   = "ec2-user"
  ami_arm64  = data.aws_ami.al2_arm64.id  
  ami_x86_64 = data.aws_ami.al2_x86_64.id 
  ami        = (var.arch == "arm64") ? local.ami_arm64 : local.ami_x86_64
  script     = var.cloud_init_script_al2
}

output Instance {
  value = <<EOF


---- You can SSH directly to the Linux instance by typing the following ssh command
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo16_inst1.public_ip}

---- Alternatively, you can add the following lines to your file $HOME/.ssh/config and then just run "ssh d16"

Host d16
        Hostname ${aws_eip.demo16_inst1.public_ip}
        User ${local.username}
        IdentityFile ${var.private_sshkey_path}


EOF
}