# ------ Create a SSH key pair for webservers
resource tls_private_key ssh_key_websrv {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh_key_websrv_public {
  content  = tls_private_key.ssh_key_websrv.public_key_openssh
  filename = var.websrv_public_sshkey_path
}

resource local_file ssh_key_websrv_private {
  content  = tls_private_key.ssh_key_websrv.private_key_pem
  filename = var.websrv_private_sshkey_path
  file_permission = "0600"
}

resource aws_key_pair demo04c_kp_websrv {
  key_name   = "demo04c-websrv"
  public_key = tls_private_key.ssh_key_websrv.public_key_openssh
}
