# ------ SSH key pair for websrv
resource tls_private_key ssh_demo15b_acct1_pvd_websrv {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh_demo15b_acct1_pvd_websrv_public {
  content  = tls_private_key.ssh_demo15b_acct1_pvd_websrv.public_key_openssh
  filename = var.acct1_pvd_websrv_public_sshkey_path
}

resource local_file ssh_demo15b_acct1_pvd_websrv_private {
  content  = tls_private_key.ssh_demo15b_acct1_pvd_websrv.private_key_pem
  filename = var.acct1_pvd_websrv_private_sshkey_path
  file_permission = "0600"
}

resource aws_key_pair demo15b_acct1_pvd_websrv {
  provider   = aws.acct1
  key_name   = "demo15b_acct1_pvd_websrv_kp"
  public_key = tls_private_key.ssh_demo15b_acct1_pvd_websrv.public_key_openssh
}