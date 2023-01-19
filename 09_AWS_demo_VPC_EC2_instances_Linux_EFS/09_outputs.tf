# ------ Create a SSH config file
resource local_file sshconfig {
  content = <<EOF
Host d09-al2
          Hostname ${aws_eip.demo09_al2.public_ip}
          User ec2-user
          IdentityFile ${var.private_sshkey_path}
          StrictHostKeyChecking no
Host d09-ubuntu
          Hostname ${aws_instance.demo09_ubuntu.public_ip}
          User ubuntu
          IdentityFile ${var.private_sshkey_path}
          StrictHostKeyChecking no
EOF

  filename        = "sshcfg"
  file_permission = "0600"
}

# ------ Display the complete ssh commands needed to connect to the compute instances
output CONNECTIONS {
  value = <<EOF

  Wait a few minutes so that post-provisioning scripts can run on the compute instances
  Then you can use instructions below to connect

     ssh -F sshcfg d09-al2                 to connect to Amazon Linux 2 instance
     ssh -F sshcfg d09-ubuntu              to connect to Ubuntu instance

  The EFS filesystem should be mounted on both instances in ${var.efs_mount_point}

EOF

}