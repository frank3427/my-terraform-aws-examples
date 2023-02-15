# ------ SSH key pair 
resource tls_private_key ssh_demo91 {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh_demo91_public {
  content  = tls_private_key.ssh_demo91.public_key_openssh
  filename = var.public_sshkey_path
}

resource local_file ssh_demo91_private {
  content  = tls_private_key.ssh_demo91.private_key_pem
  filename = var.private_sshkey_path
  file_permission = "0600"
}

resource aws_key_pair demo91_acct1 {
  provider   = aws.acct1
  key_name   = "demo91_kp"
  public_key = tls_private_key.ssh_demo91.public_key_openssh
}

resource aws_key_pair demo91_acct2 {
  provider   = aws.acct2
  key_name   = "demo91_kp"
  public_key = tls_private_key.ssh_demo91.public_key_openssh
}