# ------ optional: Create an Elastic IP address
# ------           to have a public IP address for EC2 instance persistent across stop/start
resource aws_eip demo02_inst1 {
  instance = aws_instance.demo02_inst1.id
  vpc      = true
  tags     = { Name = "demo02-win" }
}

# ------ Create a RSA key pair (to encrypt/decrypt Windows password) 
resource tls_private_key demo02 {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource local_file demo02-public {
  content  = tls_private_key.demo02.public_key_openssh
  filename = var.public_rsakey_path
}

resource local_file demo02-private {
  content  = tls_private_key.demo02.private_key_pem
  filename = var.private_rsakey_path
  file_permission = "0600"
}

resource aws_key_pair demo02_kp1 {
  key_name   = "demo02-kp1"
  public_key = tls_private_key.demo02.public_key_openssh
}

# ------ Create an EC2 instance
resource aws_instance demo02_inst1 {
  # ignore change in cloud-init file after provisioning
  lifecycle {
    ignore_changes = [
      user_data_base64
    ]
  }
  availability_zone      = "${var.aws_region}${var.az}"
  instance_type          = var.inst1_type
  ami                    = data.aws_ami.win2022.id
  key_name               = aws_key_pair.demo02_kp1.id
  subnet_id              = aws_subnet.demo02_public.id
  vpc_security_group_ids = [ aws_security_group.demo02_sg1.id ] 
  tags                   = { Name = "demo02-win" }
  get_password_data      = true    
  iam_instance_profile   = "AmazonSSMRoleForInstancesQuickSetup"  # needed for easy connection in Systems Manager      
}

# ------ Display the command needed to connect to the instance
output Instance {
  sensitive = false
  value = <<EOF

  To connect to this Windows instance, use your RDP client using following parameters:
  - public IP : ${aws_eip.demo02_inst1.public_ip}
  - User      : Administrator (for english version of Windows)
  - Password  : see content in file '${var.decrypted_pwd_file}'

  You can also use RDP file 'demo02_inst1.rdp' with your RDP client

EOF
}

resource local_file demo02_inst1_rdp {
  depends_on      = [ aws_eip.demo02_inst1 ]
  filename        = "demo02_inst1.rdp"
  file_permission = "0600"
  content         = <<EOF
auto connect:i:1
full address:s:${aws_eip.demo02_inst1.public_ip}
username:s:Administrator
EOF
}

resource local_file demo02_inst1_pwd {
  depends_on      = [ aws_eip.demo02_inst1 ]
  filename        = var.decrypted_pwd_file
  file_permission = "0600"
  content         = rsadecrypt(aws_instance.demo02_inst1.password_data, tls_private_key.demo02.private_key_pem)
}

# # ------ Alternative solution to display decrypted password
# resource local_file demo02_inst1_crypted_passwd {
#   depends_on      = [ aws_instance.demo02_inst1 ]
#   filename        = var.crypted_pwd_file
#   file_permission = "0600"
#   content         = aws_instance.demo02_inst1.password_data
# }

# output Administrator_Password {
#     value = <<EOF
#   To decrypt the password, use the command below:
#     base64 -d < ${var.crypted_pwd_file} | openssl rsautl -decrypt -inkey ${var.private_rsakey_path}; echo
# EOF
# }