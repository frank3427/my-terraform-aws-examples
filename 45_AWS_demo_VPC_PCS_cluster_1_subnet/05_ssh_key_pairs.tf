# ------ SSH key pair for compute nodes
resource tls_private_key ssh_demo45a_cpt_nodes {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource local_file ssh_demo45a_cpt_nodes_public {
  content  = tls_private_key.ssh_demo45a_cpt_nodes.public_key_openssh
  filename = var.cpt_nodes_public_sshkey_path
}

resource local_file ssh_demo45a_cpt_nodes_private {
  content  = tls_private_key.ssh_demo45a_cpt_nodes.private_key_pem
  filename = var.cpt_nodes_private_sshkey_path
  file_permission = "0600"
}

resource aws_key_pair demo45a_cpt_nodes {
  key_name   = "demo45a_cpt_nodes_kp"
  public_key = tls_private_key.ssh_demo45a_cpt_nodes.public_key_openssh
}