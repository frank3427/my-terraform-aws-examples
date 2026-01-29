# only use PCS compatible AMIs (sample or custom)
# see https://docs.aws.amazon.com/pcs/latest/userguide/working-with_ami.html

# on Jan 22, 2025: only supported OS is AL2, only supported scheduler is Slurm

# -------- Create a Launch template for compute nodes
resource aws_launch_template demo45a_cpt_nodes {
  name      = "demo45a-cpt-nodes"
  image_id  = data.aws_ami.pcs_slurm_x64.id
  key_name  = aws_key_pair.demo45a_cpt_nodes.id
  user_data = base64encode(templatefile(var.cpt_nodes_cloud_init_template, {
                              param_efs_fsid         = aws_efs_file_system.demo45a.id,
                              param_efs_mntpt        = var.efs_mountpoint,
                              param_lustre_mntpt     = var.fsx_lustre_mountpoint,
                              param_lustre_dnsname   = aws_fsx_lustre_file_system.demo45a_lustre.dns_name,
                              param_lustre_mountname = aws_fsx_lustre_file_system.demo45a_lustre.mount_name
  }))
  network_interfaces {
    security_groups = [ aws_security_group.demo45a.id ]
  }
}