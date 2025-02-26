# data aws_ec2_instance demo45_node_group_login_nodes {
#     filter {
#         name = "aws:pcs:compute-node-group-id"
#         values = ["${awscc_pcs_compute_node_group.xx.id}"]
#     }
# }

resource local_file create_ssh_config_file {
    filename = "tmp3_create_ssh_config_file.sh"
    content = <<EOF

CPT_NODE_GRP_ID=`grep demo45a-cpt-nodes-group ${local.nodegrp_ids_file} | cut -f2`

PUBLIC_IPS=`aws ec2 describe-instances \
    --region ${var.aws_region} \
    --filters "Name=tag:aws:pcs:compute-node-group-id,Values=$CPT_NODE_GRP_ID" "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].[PublicIpAddress]' \
    --output text`

rm -f ${local.sshcfg_file}

cpt=0
for public_ip in $PUBLIC_IPS
do
    cpt=$((cpt+1))
    cat >> ${local.sshcfg_file} <<EOT
Host d45a-node$cpt
          Hostname $public_ip
          User ${local.username}
          IdentityFile ${var.cpt_nodes_private_sshkey_path}
          StrictHostKeyChecking no
EOT
done

EOF

}

# ------ Display the complete ssh command needed to connect to the login node
output Instructions {
  value = templatefile("templates/outputs.tpl", {
    script1      = local_file.create_pcs_cpt_nodes_group.filename,
    script2      = local_file.create_pcs_queue.filename,
    script3      = local_file.create_ssh_config_file.filename,
    nb_nodes     = var.cpt_nodes_count,
    sshcfg_file  = local.sshcfg_file,
    scripts_dir  = var.scripts_dir,
    efs_mntpt    = var.efs_mountpoint,
    lustre_mntpt = var.fsx_lustre_mountpoint,
    slurm_queue  = var.slurm_queue
  })
}

locals {
    username    = "ec2-user"   
    sshcfg_file = "sshcfg" 
}
