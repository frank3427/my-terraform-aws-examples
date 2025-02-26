# ------ SSH key pair for opc user
resource tls_private_key ssh-demo06c {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh-demo06c-public {
  content  = tls_private_key.ssh-demo06c.public_key_openssh
  filename = var.public_sshkey_path
}

resource local_file ssh-demo06c-private {
  content  = tls_private_key.ssh-demo06c.private_key_pem
  filename = var.private_sshkey_path
  file_permission = "0600"
}

# ------ Create a SSH key pair from public key file
resource aws_key_pair demo06c_kp {
  key_name   = "demo06c-kp"
  public_key = tls_private_key.ssh-demo06c.public_key_openssh
}