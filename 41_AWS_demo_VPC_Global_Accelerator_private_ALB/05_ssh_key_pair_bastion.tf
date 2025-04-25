# ------ SSH key pair for bastion
resource tls_private_key ssh_demo41_bastion {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh_demo41_bastion_public {
  content  = tls_private_key.ssh_demo41_bastion.public_key_openssh
  filename = var.bastion_public_sshkey_path
}

resource local_file ssh_demo41_bastion_private {
  content  = tls_private_key.ssh_demo41_bastion.private_key_pem
  filename = var.bastion_private_sshkey_path
  file_permission = "0600"
}

resource aws_key_pair demo41_bastion {
  key_name   = "demo41_bastion_kp"
  public_key = tls_private_key.ssh_demo41_bastion.public_key_openssh
}