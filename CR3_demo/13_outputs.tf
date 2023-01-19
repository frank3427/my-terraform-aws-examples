# ------ Create a SSH config file
resource local_file sshconfig {
  content = <<EOF
Host bastion
          Hostname ${aws_eip.cr3_r1_bastion.public_ip}
          User ec2-user
          IdentityFile ${var.private_sshkey_path[0]}
          StrictHostKeyChecking no
Host ws1
          Hostname ${aws_instance.cr3_r1_websrv[0].private_ip}
          User ec2-user
          IdentityFile ${var.private_sshkey_path[1]}
          StrictHostKeyChecking no
          ProxyJump bastion
Host ws2
          Hostname ${aws_instance.cr3_r1_websrv[1].private_ip}
          User ec2-user
          IdentityFile ${var.private_sshkey_path[1]}
          StrictHostKeyChecking no
          ProxyJump bastion
Host ws2
          Hostname ${aws_instance.cr3_r1_websrv[2].private_ip}
          User ec2-user
          IdentityFile ${var.private_sshkey_path[1]}
          StrictHostKeyChecking no
          ProxyJump bastion
Host wsdr
          Hostname ${aws_eip.cr3_r2_dr.public_ip}
          User ec2-user
          IdentityFile ${var.private_sshkey_path[2]}
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

  1) ---- SSH connection to compute instances
     Run one of following commands on your Linux/MacOS desktop/laptop

     ssh -F sshcfg bastion             to connect to bastion host on region #1
     ssh -F sshcfg ws1                 to connect to Web server #1 on region #1
     ssh -F sshcfg ws2                 to connect to Web server #2 on region #1
     ssh -F sshcfg ws3                 to connect to Web server #3 on region #1
     ssh -F sshcfg wsdr                to connect to DR Web server on region #2

  2) ---- HTTP connection
     Open the following URLs in your Web browser: 
     - Primary site (Application Load Balancer): https://${var.dns_name_primary}
     - Secondary site (standalone EC2 instance): http://${var.dns_name_secondary}

EOF

}