# ------ SSH key pair 
resource tls_private_key ssh_demo11b {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh_demo11b_public {
  content  = tls_private_key.ssh_demo11b.public_key_openssh
  filename = var.public_sshkey_path
}

resource local_file ssh_demo11b_private {
  content  = tls_private_key.ssh_demo11b.private_key_pem
  filename = var.private_sshkey_path
  file_permission = "0600"
}

resource aws_key_pair demo11b {
  key_name   = "demo11b_kp"
  public_key = tls_private_key.ssh_demo11b.public_key_openssh
}