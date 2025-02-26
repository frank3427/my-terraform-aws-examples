# ------ SSH key pair for db_client
resource tls_private_key ssh_demo36_db_client {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh_demo36_db_client_public {
  content  = tls_private_key.ssh_demo36_db_client.public_key_openssh
  filename = var.db_client_public_sshkey_path
}

resource local_file ssh_demo36_db_client_private {
  content  = tls_private_key.ssh_demo36_db_client.private_key_pem
  filename = var.db_client_private_sshkey_path
  file_permission = "0600"
}

resource aws_key_pair demo36_db_client {
  key_name   = "demo36_db_client_kp"
  public_key = tls_private_key.ssh_demo36_db_client.public_key_openssh
}