# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo14_inst1 {
  instance = aws_instance.demo14_inst1.id
  vpc      = true
  tags     = { Name = "demo14-inst1" }
}

# ------ Create an EC2 instance
resource aws_instance demo14_inst1 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.inst1_type
  ami                    = local.ami
  key_name               = aws_key_pair.demo14.id
  subnet_id              = aws_subnet.demo14_public.id
  vpc_security_group_ids = [ aws_default_security_group.demo14.id ] 
  tags                   = { Name = "demo14-inst1" }
  user_data_base64       = base64encode(file(var.cloud_init_script_al2)) 
  private_ip             = var.inst1_private_ip   # optional  
  #iam_instance_profile   = "AmazonSSMRoleForInstancesQuickSetup"  # needed for easy connection in Systems Manager      
}

# ------ Display the complete ssh command needed to connect to the instance
locals {
  username   = "ec2-user"
  ami        = (var.arch == "arm64") ? data.aws_ami.al2_arm64.id : data.aws_ami.al2_x86_64.id
}

output Instance {
  value = <<EOF


---- You can SSH directly to the Linux instance by typing the following ssh command
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo14_inst1.public_ip}

---- Alternatively, you can add the following lines to your file $HOME/.ssh/config and then just run "ssh d14"

Host d01
        Hostname ${aws_eip.demo14_inst1.public_ip}
        User ${local.username}
        IdentityFile ${var.private_sshkey_path}


EOF
}