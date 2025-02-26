# ------ SSH key pair 
resource tls_private_key ssh_demo13c {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh_demo13c_public {
  content  = tls_private_key.ssh_demo13c.public_key_openssh
  filename = var.public_sshkey_path
}

resource local_file ssh_demo13c_private {
  content  = tls_private_key.ssh_demo13c.private_key_pem
  filename = var.private_sshkey_path
  file_permission = "0600"
}

resource aws_key_pair demo13c {
  key_name   = "demo13c_kp"
  public_key = tls_private_key.ssh_demo13c.public_key_openssh
}