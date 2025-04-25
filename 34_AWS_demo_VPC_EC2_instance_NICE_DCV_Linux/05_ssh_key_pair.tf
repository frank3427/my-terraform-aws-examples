# ------ SSH key pair 
resource tls_private_key ssh_demo34 {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh_demo34_public {
  content  = tls_private_key.ssh_demo34.public_key_openssh
  filename = var.public_sshkey_path
}

resource local_file ssh_demo34_private {
  content  = tls_private_key.ssh_demo34.private_key_pem
  filename = var.private_sshkey_path
  file_permission = "0600"
}

resource aws_key_pair demo34 {
  key_name   = "demo34_kp"
  public_key = tls_private_key.ssh_demo34.public_key_openssh
}