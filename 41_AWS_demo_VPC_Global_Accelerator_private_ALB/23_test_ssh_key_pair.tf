# ------ SSH key pair for test instance
resource "tls_private_key" "ssh_demo41_test" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "ssh_demo41_test_public" {
  content  = tls_private_key.ssh_demo41_test.public_key_openssh
  filename = var.test_public_sshkey_path
}

resource "local_file" "ssh_demo41_test_private" {
  content         = tls_private_key.ssh_demo41_test.private_key_pem
  filename        = var.test_private_sshkey_path
  file_permission = "0600"
}

resource "aws_key_pair" "demo41_test" {
  region     = var.test_region
  key_name   = "demo41_test_kp"
  public_key = tls_private_key.ssh_demo41_test.public_key_openssh
}
