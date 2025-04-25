# ------ SSH key pair 
resource tls_private_key ssh_demo31 {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh_demo31_public {
  content  = tls_private_key.ssh_demo31.public_key_openssh
  filename = var.public_sshkey_path
}

resource local_file ssh_demo31_private {
  content  = tls_private_key.ssh_demo31.private_key_pem
  filename = var.private_sshkey_path
  file_permission = "0600"
}

resource aws_key_pair demo31 {
  key_name   = "demo31_kp"
  public_key = tls_private_key.ssh_demo31.public_key_openssh
}