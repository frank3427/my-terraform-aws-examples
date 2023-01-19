# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo08_al2 {
  instance = aws_instance.demo08_al2.id
  vpc      = true
  tags     = { Name = "demo08-al2" }
}

# ------ Create an EC2 instance
resource aws_instance demo08_al2 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.al2_inst_type
  ami                    = data.aws_ami.al2_arm64.id
  key_name               = aws_key_pair.demo08.id
  subnet_id              = aws_subnet.demo08_public.id
  vpc_security_group_ids = [ aws_default_security_group.demo08.id ] 
  tags                   = { Name = "demo08-al2" }
  user_data_base64       = base64encode(replace(local.cloud_init,"<DNS_NAME>",aws_efs_file_system.demo08.dns_name))
  private_ip             = var.al2_private_ip   # optional        
  iam_instance_profile   = "AmazonSSMRoleForInstancesQuickSetup"  # needed for easy connection in Systems Manager      
}

# ------ Display the complete ssh command needed to connect to the instance
locals {
  username   = "ec2-user"
  cloud_init = replace(file(var.al2_cloud_init_script),"<MOUNT_POINT>",var.efs_mount_point)
}

output Instance {
  value = <<EOF


---- You can SSH directly to the Linux instance by typing the following ssh command
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo08_al2.public_ip}

---- Alternatively, you can add the following lines to your file $HOME/.ssh/config and then just run "ssh d08"

Host d08
        Hostname ${aws_eip.demo08_al2.public_ip}
        User ${local.username}
        IdentityFile ${var.private_sshkey_path}

---- The EFS filesystem is mounted automatically at ${var.efs_mount_point}

EOF
}