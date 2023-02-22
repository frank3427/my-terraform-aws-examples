# ------ Create a SSH config file
resource local_file sshconfig {
  content = <<EOF
Host d19-bastion
          Hostname ${aws_eip.demo19_bastion.public_ip}
          User ec2-user
          IdentityFile ${var.bastion_private_sshkey_path}
          StrictHostKeyChecking no
Host d19-ws1
          Hostname ${aws_instance.demo19_websrv[0].private_ip}
          User ec2-user
          IdentityFile ${var.websrv_private_sshkey_path}
          StrictHostKeyChecking no
          ProxyJump d19-bastion
Host d19-ws2
          Hostname ${aws_instance.demo19_websrv[1].private_ip}
          User ec2-user
          IdentityFile ${var.websrv_private_sshkey_path}
          StrictHostKeyChecking no
          ProxyJump d19-bastion
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

     ssh -F sshcfg d19-bastion             to connect to bastion host
     ssh -F sshcfg d19-ws1                 to connect to Web server #1
     ssh -F sshcfg d19-ws2                 to connect to Web server #2

  2) ---- HTTP connection to virtual IP (VIP)
     Open the following URL in your Web browser:
     http://${aws_eip.demo19_vip.public_ip}

     Notes:
     - The VIP is currently attached to web server #${var.websrv_vip_owner}
     - To move the VIP to the other web server, modify variable websrv_vip_owner in terraform.tfvars
       then re-run terraform apply

EOF

}
