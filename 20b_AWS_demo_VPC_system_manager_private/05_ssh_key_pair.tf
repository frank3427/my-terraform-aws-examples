# ------ SSH key pair 
resource tls_private_key ssh_demo20b {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh_demo20b_public {
  content  = tls_private_key.ssh_demo20b.public_key_openssh
  filename = var.public_sshkey_path
}

resource local_file ssh_demo20b_private {
  content  = tls_private_key.ssh_demo20b.private_key_pem
  filename = var.private_sshkey_path
  file_permission = "0600"
}

resource aws_key_pair demo20b {
  key_name   = "demo20b_kp"
  public_key = tls_private_key.ssh_demo20b.public_key_openssh
}