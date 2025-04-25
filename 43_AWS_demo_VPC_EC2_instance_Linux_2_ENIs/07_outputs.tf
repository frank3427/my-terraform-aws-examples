locals {
  username   = (var.linux == "ubuntu") ? "ubuntu" : "ec2-user"
  script     = (var.linux == "ubuntu") ? var.cloud_init_script_ubuntu : var.cloud_init_script_al
}

output Instructions {
  value = <<EOF


---- You can SSH to the Linux EC2 instance using primary ENI by typing the following ssh command
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo43_inst1.public_ip}

---- You can access Web Server on the Linux EC2 instance using secondary ENI 
http://${aws_eip.demo43_inst1_eni2.public_ip}

EOF
}