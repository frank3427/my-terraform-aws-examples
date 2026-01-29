# ------ Get the public IP addresses of the compute nodes using tags
resource null_resource wait_for_nodes {
  depends_on = [ awscc_pcs_compute_node_group.demo45a_ng1 ]
  provisioner "local-exec" {
    command = "sleep 60"
  }
}

data aws_instances cpt_nodes {
  depends_on = [ null_resource.wait_for_nodes ]
  filter {
    name   = "tag:aws:pcs:compute-node-group-id"
    values = [ awscc_pcs_compute_node_group.demo45a_ng1.compute_node_group_id ]
  }
}

output cpt_nodes_public_ips {
  value = local.compute_nodes_public_ips
}

locals {
    username                 = "ec2-user"   
    sshcfg_file              = "sshcfg" 
    compute_nodes_public_ips = data.aws_instances.cpt_nodes.public_ips
}

# ------ Create a SSH config file
resource local_file sshconfig {
  content = templatefile("templates/sshcfg.tpl", {
    username                   = local.username,
    public_ip_nodes            = local.compute_nodes_public_ips,
    ssh_private_key_file_nodes = var.cpt_nodes_private_sshkey_path
  })
  filename        = local.sshcfg_file
  file_permission = "0600"
}

# ------ Display the complete ssh command needed to connect to the login node
output Instructions {
  value = templatefile("templates/outputs.tpl", {
    nb_nodes     = var.cpt_nodes_count,
    sshcfg_file  = local.sshcfg_file,
    scripts_dir  = var.scripts_dir,
    efs_mntpt    = var.efs_mountpoint,
    lustre_mntpt = var.fsx_lustre_mountpoint,
    slurm_queue  = var.slurm_queue
  })
}


