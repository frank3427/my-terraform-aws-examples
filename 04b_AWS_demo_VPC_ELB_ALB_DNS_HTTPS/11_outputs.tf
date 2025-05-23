# ------ Create a SSH config file
resource local_file sshconfig {
  content = <<EOF
Host d04b-bastion
          Hostname ${aws_eip.demo04b_bastion.public_ip}
          User ec2-user
          IdentityFile ${var.bastion_private_sshkey_path}
          StrictHostKeyChecking no
Host d04b-ws1
          Hostname ${aws_instance.demo04b_websrv[0].private_ip}
          User ec2-user
          IdentityFile ${var.websrv_private_sshkey_path}
          StrictHostKeyChecking no
          ProxyJump d04b-bastion
Host d04b-ws2
          Hostname ${aws_instance.demo04b_websrv[1].private_ip}
          User ec2-user
          IdentityFile ${var.websrv_private_sshkey_path}
          StrictHostKeyChecking no
          ProxyJump d04b-bastion
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

     ssh -F sshcfg d04b-bastion             to connect to bastion host
     ssh -F sshcfg d04b-ws1                 to connect to Web server #1
     ssh -F sshcfg d04b-ws2                 to connect to Web server #2

  2) ---- HTTPS connection to public load balancer
     Open the following URL in your Web browser:
     https://${var.dns_name}
     or 
     http://${var.dns_name} (should be redirected to https)

     You can see access logs of Web servers in /var/log/httpd/access_log files
     source IP address = private IPs of ALB (1 private IP per subnet/AZ)

     
EOF

}
