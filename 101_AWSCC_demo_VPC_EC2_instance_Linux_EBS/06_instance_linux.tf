# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource awscc_ec2_eip demo101_inst1 {
  instance_id = aws_instance.demo101_inst1.id
  domain      = "vpc"
  tags        = [{ key = "Name", value = "demo101-inst1" }]
}

# ------ Create an EC2 instance
resource aws_instance demo101_inst1 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.inst1_type
  ami                    = local.ami
  key_name               = aws_key_pair.demo101.id
  subnet_id              = awscc_ec2_subnet.demo101_public.id
  vpc_security_group_ids = [ aws_default_security_group.demo101.id ] 
  tags                   = { Name = "demo101-inst1" }
  user_data_base64       = base64encode(file(local.script)) 
  private_ip             = var.inst1_private_ip   # optional  
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo101-inst1-boot" }
  }
}

# ------ Display the complete ssh command needed to connect to the instance
locals {
  username   = (var.linux == "al2") ? "ec2-user" : "ubuntu"
  ami_arm64  = (var.linux == "al2") ? data.aws_ami.al2_arm64.id  : data.aws_ami.ubuntu_2204_arm64.id
  ami_x86_64 = (var.linux == "al2") ? data.aws_ami.al2_x86_64.id : data.aws_ami.ubuntu_2204_x86_64.id
  ami        = (var.arch == "arm64") ? local.ami_arm64 : local.ami_x86_64
  script     = (var.linux == "al2") ? var.cloud_init_script_al2 : var.cloud_init_script_ubuntu
}

output Instance {
  value = <<EOF


---- You can SSH directly to the Linux instance by typing the following ssh command
ssh -i ${var.private_sshkey_path} ${local.username}@${awscc_ec2_eip.demo101_inst1.public_ip}

---- Alternatively, you can add the following lines to your file $HOME/.ssh/config and then just run "ssh d01"

Host d01
        Hostname ${awscc_ec2_eip.demo101_inst1.public_ip}
        User ${local.username}
        IdentityFile ${var.private_sshkey_path}


EOF
}