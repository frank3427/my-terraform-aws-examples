# ------ SSH key pair for opc user
resource tls_private_key ssh-demo06b {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh-demo06b-public {
  content  = tls_private_key.ssh-demo06b.public_key_openssh
  filename = var.public_sshkey_path
}

resource local_file ssh-demo06b-private {
  content  = tls_private_key.ssh-demo06b.private_key_pem
  filename = var.private_sshkey_path
  file_permission = "0600"
}

# ------ Create a SSH key pair from public key file
resource aws_key_pair demo06b_kp {
  key_name   = "demo06b-kp"
  public_key = tls_private_key.ssh-demo06b.public_key_openssh
}