# ------ SSH key pair for opc user
resource tls_private_key ssh-demo07 {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh-demo07-public {
  content  = tls_private_key.ssh-demo07.public_key_openssh
  filename = var.public_sshkey_path
}

resource local_file ssh-demo07-private {
  content  = tls_private_key.ssh-demo07.private_key_pem
  filename = var.private_sshkey_path
  file_permission = "0600"
}

# ------ Create a SSH key pair from public key file in both regions
resource aws_key_pair demo07_kp_r1 {
  provider       = aws.r1
  key_name   = "demo07-kp-r1"
  public_key = tls_private_key.ssh-demo07.public_key_openssh
}

resource aws_key_pair demo07_kp_r2 {
  provider       = aws.r2
  key_name   = "demo07-kp-r2"
  public_key = tls_private_key.ssh-demo07.public_key_openssh
}