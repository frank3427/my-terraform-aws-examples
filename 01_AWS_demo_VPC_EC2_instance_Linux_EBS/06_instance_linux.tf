# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo01_inst1 {
  instance = aws_instance.demo01_inst1.id
  vpc      = true
  tags     = { Name = "demo01-inst1" }
}

# ------ Create an EC2 instance
resource aws_instance demo01_inst1 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.inst1_type
  ami                    = local.ami
  key_name               = aws_key_pair.demo01.id
  subnet_id              = aws_subnet.demo01_public.id
  vpc_security_group_ids = [ aws_default_security_group.demo01.id ] 
  tags                   = { Name = "demo01-inst1" }
  user_data_base64       = base64encode(file(local.script)) 
  private_ip             = var.inst1_private_ip   # optional  
  #iam_instance_profile   = "AmazonSSMRoleForInstancesQuickSetup"  # needed for easy connection in Systems Manager      
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
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo01_inst1.public_ip}

---- Alternatively, you can add the following lines to your file $HOME/.ssh/config and then just run "ssh d01"

Host d01
        Hostname ${aws_eip.demo01_inst1.public_ip}
        User ${local.username}
        IdentityFile ${var.private_sshkey_path}


EOF
}