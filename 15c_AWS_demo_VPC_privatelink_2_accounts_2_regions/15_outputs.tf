# ------ Create a SSH config file
resource local_file sshconfig {
  content = <<EOF
Host d15c-acct2_csm-bastion
          Hostname ${aws_eip.demo15c_acct2_csm_bastion.public_ip}
          User ec2-user
          IdentityFile ${var.acct2_csm_bastion_private_sshkey_path}
          StrictHostKeyChecking no
Host d15c-acct1_pvd-bastion
          Hostname ${aws_eip.demo15c_acct1_pvd_bastion.public_ip}
          User ec2-user
          IdentityFile ${var.acct1_pvd_bastion_private_sshkey_path}
          StrictHostKeyChecking no
Host d15c-acct1_pvd-ws1
          Hostname ${aws_instance.demo15c_acct1_pvd_websrv[0].private_ip}
          User ec2-user
          IdentityFile ${var.acct1_pvd_websrv_private_sshkey_path}
          StrictHostKeyChecking no
          ProxyJump d15-acct1_pvd-bastion
Host d15c-acct1_pvd-ws2
          Hostname ${aws_instance.demo15c_acct1_pvd_websrv[1].private_ip}
          User ec2-user
          IdentityFile ${var.acct1_pvd_websrv_private_sshkey_path}
          StrictHostKeyChecking no
          ProxyJump d15-acct1_pvd-bastion
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

     ssh -F sshcfg d15c-acct2_csm-bastion             to connect to bastion host in CONSUMER VPC
     ssh -F sshcfg d15c-acct1_pvd-bastion             to connect to bastion host in PROVIDER VPC
     ssh -F sshcfg d15c-acct1_pvd-ws1                 to connect to Web server #1 in PROVIDER VPC
     ssh -F sshcfg d15c-acct1_pvd-ws2                 to connect to Web server #2 in PROVIDER VPC

  2) ---- To check the PRIVATE LINK between CONSUMER VPC and PROVIDER VPC
     a) Connect to EC2 instance in CONSUMER VPC with following command
        ssh -F sshcfg d15c-acct2_csm-bastion

     b) Check HTTP access to Web Server in PROVIDER VPC with following command
        curl http://${aws_vpc_endpoint.demo15c_acct2_csm.dns_entry[0].dns_name}

EOF

}

#dig google.com +short
