# ------ SSH key pair 
resource tls_private_key ssh_demo13d {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh_demo13d_public {
  content  = tls_private_key.ssh_demo13d.public_key_openssh
  filename = var.public_sshkey_path
}

resource local_file ssh_demo13d_private {
  content  = tls_private_key.ssh_demo13d.private_key_pem
  filename = var.private_sshkey_path
  file_permission = "0600"
}

resource aws_key_pair demo13d {
  key_name   = "demo13d_kp"
  public_key = tls_private_key.ssh_demo13d.public_key_openssh
}