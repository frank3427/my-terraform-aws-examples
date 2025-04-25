# ------ SSH key pair 
resource tls_private_key ssh_demo35 {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh_demo35_public {
  content  = tls_private_key.ssh_demo35.public_key_openssh
  filename = var.public_sshkey_path
}

resource local_file ssh_demo35_private {
  content  = tls_private_key.ssh_demo35.private_key_pem
  filename = var.private_sshkey_path
  file_permission = "0600"
}

resource aws_key_pair demo35 {
  key_name   = "demo35_kp"
  public_key = tls_private_key.ssh_demo35.public_key_openssh
}