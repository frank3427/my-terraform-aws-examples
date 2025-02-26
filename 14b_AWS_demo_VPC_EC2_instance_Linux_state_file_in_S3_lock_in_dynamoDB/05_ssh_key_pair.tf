# ------ SSH key pair 
resource tls_private_key ssh_demo14b {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh_demo14b_public {
  content  = tls_private_key.ssh_demo14b.public_key_openssh
  filename = var.public_sshkey_path
}

resource local_file ssh_demo14b_private {
  content  = tls_private_key.ssh_demo14b.private_key_pem
  filename = var.private_sshkey_path
  file_permission = "0600"
}

resource aws_key_pair demo14b {
  key_name   = "demo14b_kp"
  public_key = tls_private_key.ssh_demo14b.public_key_openssh
}