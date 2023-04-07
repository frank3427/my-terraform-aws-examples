# ------ Create a SSH config file
resource local_file sshconfig {
  content = <<EOF
Host d22-bastion
          Hostname ${aws_eip.demo22_bastion.public_ip}
          User ec2-user
          IdentityFile ${var.bastion_private_sshkey_path}
          StrictHostKeyChecking no
Host d22-ws1
          Hostname ${aws_instance.demo22_websrv[0].private_ip}
          User ec2-user
          IdentityFile ${var.websrv_private_sshkey_path}
          StrictHostKeyChecking no
          ProxyJump d22-bastion
Host d22-ws2
          Hostname ${aws_instance.demo22_websrv[1].private_ip}
          User ec2-user
          IdentityFile ${var.websrv_private_sshkey_path}
          StrictHostKeyChecking no
          ProxyJump d22-bastion
Host d22-ws3
          Hostname ${aws_instance.demo22_websrv[2].private_ip}
          User ec2-user
          IdentityFile ${var.websrv_private_sshkey_path}
          StrictHostKeyChecking no
          ProxyJump d22-bastion
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

     ssh -F sshcfg d22-bastion             to connect to bastion host
     ssh -F sshcfg d22-ws1                 to connect to Web server #1
     ssh -F sshcfg d22-ws2                 to connect to Web server #2
     ssh -F sshcfg d22-ws3                 to connect to Web server #3

  2) ---- HTTP connection to public Classic load balancer
     Open the following URL in your Web browser:
     http://${aws_elb.demo22_clb.dns_name}
     

  REMINDER: Classic load balancer is being deprecated, so please using Network LB or Application LB instead.
  
EOF

}
