# ------ Create a SSH config file
resource "local_file" "sshconfig" {
  content = <<EOF
Host d04c-bastion
          Hostname ${aws_instance.demo04c_bastion.public_ip}
          User ec2-user
          IdentityFile ${var.bastion_private_sshkey_path}
          StrictHostKeyChecking no
Host d04c-ws1
          Hostname ${aws_instance.demo04c_websrv[0].private_ip}
          User ec2-user
          IdentityFile ${var.websrv_private_sshkey_path}
          StrictHostKeyChecking no
          ProxyJump d04c-bastion
Host d04c-ws2
          Hostname ${aws_instance.demo04c_websrv[1].private_ip}
          User ec2-user
          IdentityFile ${var.websrv_private_sshkey_path}
          StrictHostKeyChecking no
          ProxyJump d04c-bastion
EOF

  filename        = "sshcfg"
  file_permission = "0600"
}

# ------ Display the complete ssh commands needed to connect to the compute instances
output "CONNECTIONS" {
  value = <<EOF

  Wait a few minutes so that post-provisioning scripts can run on the compute instances
  Then you can use instructions below to connect

  1) ---- SSH connection to compute instances
     Run one of following commands on your Linux/MacOS desktop/laptop

     ssh -F sshcfg d04c-bastion             to connect to bastion host
     ssh -F sshcfg d04c-ws1                 to connect to Web server #1
     ssh -F sshcfg d04c-ws2                 to connect to Web server #2

  2) ---- HTTP connection to public load balancer
     Open the following URL in your Web browser:
     http://${aws_lb.demo04c_nlb.dns_name}

  3) ---- HTTP connection to internal load balancer (via bastion)
     Internal ALB DNS: ${aws_lb.demo04c_alb.dns_name}

EOF

}
