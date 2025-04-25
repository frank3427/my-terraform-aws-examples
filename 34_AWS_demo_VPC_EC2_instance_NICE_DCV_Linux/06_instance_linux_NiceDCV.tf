# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo34_inst1 {
  instance = aws_instance.demo34_inst1.id
  domain   = "vpc"
  tags     = { Name = "demo34-inst1" }
}

# ------ Create an EC2 instance
resource aws_instance demo34_inst1 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.inst1_type
  ami                    = local.ami
  key_name               = aws_key_pair.demo34.id
  subnet_id              = aws_subnet.demo34_public.id
  vpc_security_group_ids = [ aws_default_security_group.demo34.id ] 
  tags                   = { Name = "demo34-inst1" }
  user_data_base64       = base64encode(file(local.script)) 
  private_ip             = var.inst1_private_ip   # optional  
  root_block_device {
    encrypted   = true      # use default KMS key aws/ebs
    volume_type = "gp3"
    tags        = { "Name" = "demo34-inst1-boot" }
  }
}

# -- genereate a random password for default user and new user
resource random_string demo34_user1_password {
  # must contains at least 2 upper case letters, 2 lower case letters, 2 numbers and 2 special characters
  length      = 12
  upper       = true
  min_upper   = 2
  lower       = true
  min_lower   = 2
  numeric     = true
  min_numeric = 2
  special     = true
  min_special = 2
  override_special = "#-_"   # use only special characters in this list
}

resource random_string demo34_user2_password {
  # must contains at least 2 upper case letters, 2 lower case letters, 2 numbers and 2 special characters
  length      = 12
  upper       = true
  min_upper   = 2
  lower       = true
  min_lower   = 2
  numeric     = true
  min_numeric = 2
  special     = true
  min_special = 2
  override_special = "#-_"   # use only special characters in this list
}

# ------ Display the complete ssh command needed to connect to the instance
locals {
  username   = "ec2-user"
  ami        = data.aws_ami.al2_x86_64.id
  script     = var.cloud_init_script_al2
  username2  = "chris"
  password   = random_string.demo34_user1_password.result
  password2  = random_string.demo34_user2_password.result
}

output Instance {
  value = <<EOF

---- You can SSH directly to the Linux instance by typing the following ssh command
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo34_inst1.public_ip}

---- Alternatively, you can add the following lines to your file $HOME/.ssh/config and then just run "ssh d01"

Host d34
        Hostname ${aws_eip.demo34_inst1.public_ip}
        User ${local.username}
        IdentityFile ${var.private_sshkey_path}

---- Once Connected, you can use following commands:
list Nvidia GPUs:
    nvidia-smi                                         

Checking Nice DCV installation:
    sudo dcvgldiag                                      

Set a password for current user ${local.username}
    printf "${local.password}" | sudo passwd -f {local.username} --stdin

Create DCV session with ID 1 for current user ${local.username}
    dcv create-session 1                              

Create an additional user ${local.username2} then set a password for the user
    sudo useradd ${local.username2}
    printf "${local.password2}" | sudo passwd -f ${local.username2} --stdin

Create DCV session with ID 2 for different user ${local.username2}
    sudo dcv create-session 2 --user ${local.username2} --owner ${local.username2}    
    
list DCV sessions for all users
    sudo dcv list-sessions                              

Close DCV sessions
    dcv close-session 1 
    sudo dcv close-session 2 

---- You can access Nice DCV Web UI for DCV sessions using following URLs
https://${aws_eip.demo34_inst1.public_ip}:8443/#1             for session 1 (username is ${local.username}, password: ${local.password})
https://${aws_eip.demo34_inst1.public_ip}:8443/#2             for session 2 (username is ${local.username2}, password: ${local.password2})

Note: self-signed certificate use, so browser will show security warning.

Once connected to Linux Gnome Desktop, you can launch a terminal and run graphical applications (like glxgears)


EOF
}