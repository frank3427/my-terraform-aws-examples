# ------ Create a SSH config file
resource local_file sshconfig {
  content = <<EOF
Host d21-bastion
          Hostname ${aws_eip.demo21_bastion.public_ip}
          User ec2-user
          IdentityFile ${var.bastion_private_sshkey_path}
          StrictHostKeyChecking no
Host d21-ws1
          Hostname ${aws_instance.demo21_websrv[0].private_ip}
          User ec2-user
          IdentityFile ${var.websrv_private_sshkey_path}
          StrictHostKeyChecking no
          ProxyJump d21-bastion
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

     ssh -F sshcfg d21-bastion             to connect to bastion host
     ssh -F sshcfg d21-ws1                 to connect to Web server #1

  2) ---- HTTP connection to public load balancer
     Open the following URL in your Web browser from different countries
     http://${aws_lb.demo21_alb.dns_name}

     You should see that access is only allowed from FRANCE and GERMANY !
EOF

}
