# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo35_inst1 {
  instance = aws_instance.demo35_inst1.id
  domain   = "vpc"
  tags     = { Name = "demo35-inst1" }
}

# ------ Create an EC2 instance
resource aws_instance demo35_inst1 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  instance_type          = var.inst1_type
  ami                    = local.ami
  key_name               = aws_key_pair.demo35.id
  subnet_id              = aws_subnet.demo35_public[0].id
  vpc_security_group_ids = [ aws_default_security_group.demo35.id ] 
  tags                   = { Name = "demo35-client1" }
  private_ip             = var.inst1_private_ip   # optional  
  iam_instance_profile   = aws_iam_instance_profile.demo35_msk.id
  user_data_base64       = base64encode(templatefile(var.cloud_init_script, {
                              param_kafka_version     = var.msk_kafka_version,
                              param_bootstrap_servers = local.msk_bootstrap_brokers
                           }))
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo35-client1-boot" }
  }
}

# ------ Display the complete ssh command needed to connect to the instance
locals {
  username   = "ec2-user"
  ami        = (var.inst1_arch == "arm64") ? data.aws_ami.al2023_arm64.id: data.aws_ami.al2023_x86_64.id
}

output Instance {
  value = <<EOF


---- You can SSH directly to the Linux instance by typing the following ssh command
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo35_inst1.public_ip}

---- Alternatively, you can add the following lines to your file $HOME/.ssh/config and then just run "ssh d35"

Host d35
        Hostname ${aws_eip.demo35_inst1.public_ip}
        User ${local.username}
        IdentityFile ${var.private_sshkey_path}


EOF
}