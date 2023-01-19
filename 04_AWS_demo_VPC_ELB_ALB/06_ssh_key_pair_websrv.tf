# ------ SSH key pair for websrv
resource tls_private_key ssh_demo04_websrv {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh_demo04_websrv_public {
  content  = tls_private_key.ssh_demo04_websrv.public_key_openssh
  filename = var.websrv_public_sshkey_path
}

resource local_file ssh_demo04_websrv_private {
  content  = tls_private_key.ssh_demo04_websrv.private_key_pem
  filename = var.websrv_private_sshkey_path
  file_permission = "0600"
}

resource aws_key_pair demo04_websrv {
  key_name   = "demo04_websrv_kp"
  public_key = tls_private_key.ssh_demo04_websrv.public_key_openssh
}