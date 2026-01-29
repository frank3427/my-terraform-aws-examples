# ------ Create a SSH config file
resource "local_file" "sshconfig" {
  content = <<EOF
Host d40-bastion
          Hostname ${aws_eip.demo40_bastion.public_ip}
          User ec2-user
          IdentityFile ${var.bastion_private_sshkey_path}
          StrictHostKeyChecking no
Host d40-ws1
          Hostname ${aws_instance.demo40_websrv[0].private_ip}
          User ec2-user
          IdentityFile ${var.websrv_private_sshkey_path}
          StrictHostKeyChecking no
          ProxyJump d40-bastion
Host d40-ws2
          Hostname ${aws_instance.demo40_websrv[1].private_ip}
          User ec2-user
          IdentityFile ${var.websrv_private_sshkey_path}
          StrictHostKeyChecking no
          ProxyJump d40-bastion
EOF

  filename        = "sshcfg"
  file_permission = "0600"
}

# ------ Display the complete ssh commands needed to connect to the compute instances
output "CONNECTIONS" {
  value = <<EOF

  Wait a few minutes so that post-provisioning scripts can run on the compute instances
  Then you can use instructions below to connect

  1) ---- SSH connection to EC2 instances
     Run one of following commands on your Linux/MacOS desktop/laptop

     ssh -F sshcfg d40-bastion             # to connect to bastion host
     ssh -F sshcfg d40-ws1                 # to connect to Web server #1 via bastion host
     ssh -F sshcfg d40-ws2                 # to connect to Web server #2 via bastion host

     Note: you can see access logs on a webserver with following command:
     sudo tail -f /var/log/httpd/access_log
     
  2) ---- HTTPS connection to CloudFront distribution using default DNS domain name (should work)
     https://${aws_cloudfront_distribution.demo40.domain_name}

  3) ---- HTTP connection to ALB (should not work, blocked by security group)
     http://${aws_lb.demo40_alb.dns_name}

  4) ---- You can test access to CloudFront via curl (should work)
  curl https://${aws_cloudfront_distribution.demo40.domain_name}

  5) ---- You can test access to ALB (without CloudFront) via curl (should not work, blocked by security group)
  curl -H "X-Origin-Verify: ${local.demo40_secret}" \
       http://${aws_lb.demo40_alb.dns_name}
EOF

}
