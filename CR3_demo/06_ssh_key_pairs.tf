# ------ SSH key pair for opc user
resource tls_private_key ssh-cr3 {
  count     = "3"
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh-cr3-public {
  count    = "3"
  content  = tls_private_key.ssh-cr3[count.index].public_key_openssh
  filename = var.public_sshkey_path[count.index]
}

resource local_file ssh-cr3-private {
  count    = "3"
  content  = tls_private_key.ssh-cr3[count.index].private_key_pem
  filename = var.private_sshkey_path[count.index]
  file_permission = "0600"
}

# ------ Create SSH key pairs from public key file in both regions
resource aws_key_pair cr3_r1_kp {
  count      = 2
  provider   = aws.r1
  key_name   = "cr3-r1-kp${count.index + 1}"
  public_key = tls_private_key.ssh-cr3[count.index].public_key_openssh
}

resource aws_key_pair cr3_r2_kp {
  provider   = aws.r2
  key_name   = "cr3-r2-kp"
  public_key = tls_private_key.ssh-cr3[2].public_key_openssh
}