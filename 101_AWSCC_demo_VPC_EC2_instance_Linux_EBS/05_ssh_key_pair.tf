# ------ SSH key pair 
resource tls_private_key ssh_demo101 {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh_demo101_public {
  content  = tls_private_key.ssh_demo101.public_key_openssh
  filename = var.public_sshkey_path
}

resource local_file ssh_demo101_private {
  content  = tls_private_key.ssh_demo101.private_key_pem
  filename = var.private_sshkey_path
  file_permission = "0600"
}

# missing in awscc
resource aws_key_pair demo101 {
  key_name   = "demo101_kp"
  public_key = tls_private_key.ssh_demo101.public_key_openssh
}