# ------ Create a SSH config file
resource "local_file" "sshconfig" {
  content = <<EOF
Host d41-test
          Hostname ${aws_eip.demo41_test.public_ip}
          User ec2-user
          IdentityFile ${var.test_private_sshkey_path}
          StrictHostKeyChecking no
Host d41-bastion
          Hostname ${aws_eip.demo41_bastion.public_ip}
          User ec2-user
          IdentityFile ${var.bastion_private_sshkey_path}
          StrictHostKeyChecking no
Host d41-ws1
          Hostname ${aws_instance.demo41_websrv[0].private_ip}
          User ec2-user
          IdentityFile ${var.websrv_private_sshkey_path}
          StrictHostKeyChecking no
          ProxyJump d41-bastion
Host d41-ws2
          Hostname ${aws_instance.demo41_websrv[1].private_ip}
          User ec2-user
          IdentityFile ${var.websrv_private_sshkey_path}
          StrictHostKeyChecking no
          ProxyJump d41-bastion
EOF

  filename        = "sshcfg"
  file_permission = "0600"
}

# ------ Create a config file for curl detailed response times
resource "local_file" "curl_format" {
  content         = <<EOF
time_namelookup   : %%{time_namelookup}s\n
time_connect      : %%{time_connect}s\n
time_appconnect   : %%{time_appconnect}s\n
time_pretransfer  : %%{time_pretransfer}s\n
time_redirect     : %%{time_redirect}s\n
time_starttransfer: %%{time_starttransfer}s\n
----------\n
time_total        : %%{time_total}s\n
EOF
  filename        = local.curl_format_file
  file_permission = "0600"
}

# ------ Create a Bash script to run loop of tests
resource "local_file" "test_script" {
  content         = <<EOF
#!/bin/bash

TMP_FILE=toto
NB_ITERATIONS=20
NB_DIGITS=5

echo "============================ Testing WITHOUT Global Accelerator"
for i in `seq 1 $NB_ITERATIONS`; do
  curl -w "%%{time_total}\n" -H "X-Origin-Verify: ${local.demo41_secret}" http://${aws_lb.demo41_alb_public.dns_name} -o /dev/null 2>/dev/null
done | tee $TMP_FILE
printf "Average = "
echo "scale=$NB_DIGITS; ($(paste -sd+ $TMP_FILE)) / $NB_ITERATIONS" | bc
echo

echo "============================ Testing WITH Global Accelerator"
for i in `seq 1 $NB_ITERATIONS`; do
  curl -w "%%{time_total}\n" -H "X-Origin-Verify: ${local.demo41_secret}" http://${aws_globalaccelerator_accelerator.demo41.dns_name} -o /dev/null 2>/dev/null
done | tee $TMP_FILE
printf "Average = "
echo "scale=$NB_DIGITS; ($(paste -sd+ $TMP_FILE)) / $NB_ITERATIONS" | bc

rm -f $TMP_FILE
EOF
  filename        = local.curl_script_file
  file_permission = "0755"
}


locals {
  custom_header    = "X-Origin-Verify: ${local.demo41_secret}"
  curl_format_file = "curl-format.txt"
  curl_script_file = "test_curl.sh"
}

# ------ Copy test_curl.sh script to test instance
resource "null_resource" "copy_test_script" {
  # Trigger when the test script content changes or instance changes
  triggers = {
    script_content = local_file.test_script.content
    instance_id    = aws_instance.demo41_test.id
    public_ip      = aws_eip.demo41_test.public_ip
  }

  # Copy the test script to the test instance
  provisioner "file" {
    source      = local.curl_script_file
    destination = "/home/ec2-user/test_curl.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.test_private_sshkey_path)
      host        = aws_eip.demo41_test.public_ip
    }
  }

  # Make the script executable
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/test_curl.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.test_private_sshkey_path)
      host        = aws_eip.demo41_test.public_ip
    }
  }

  # Ensure the script is created first and instance is ready
  depends_on = [
    local_file.test_script,
    aws_eip.demo41_test,
    aws_instance.demo41_test
  ]
}

# ------ Display the complete ssh commands needed to connect to the compute instances
output "CONNECTIONS" {
  value = <<EOF

  Wait a few minutes so that post-provisioning scripts can run on the compute instances
  Then you can use instructions below to connect

  1) ---- Test HTTP connection to ALB WITH Global Accelerator
     curl -w "@${local.curl_format_file}" -H "X-Origin-Verify: ${local.demo41_secret}" http://${aws_globalaccelerator_accelerator.demo41.dns_name}

  2) ---- Test HTTP connection to ALB WITHOUT Global Accelerator and compare response times
     curl -w "@${local.curl_format_file}" -H "X-Origin-Verify: ${local.demo41_secret}" http://${aws_lb.demo41_alb_public.dns_name}

  3) ---- Run compare script
  ./${local.curl_script_file}

  4) ---- if needed, SSH connection to EC2 instances
     Run one of following commands on your Linux/MacOS desktop/laptop

     ssh -F sshcfg d41-test                # to connect to test host (far away from ALB)
     ssh -F sshcfg d41-bastion             # to connect to bastion host
     ssh -F sshcfg d41-ws1                 # to connect to Web server #1 via bastion host
     ssh -F sshcfg d41-ws2                 # to connect to Web server #2 via bastion host

     Note: you can see access logs on a webserver with following command:
     sudo tail -f /var/log/httpd/access_log

  5) ---- if needed, check access to private ALB from bastion host
     curl -H "X-Origin-Verify: ${local.demo41_secret}" http://${aws_lb.demo41_alb_private.dns_name}

  6) ---- You can test from Test instance (far away from ALB)
     ssh -F sshcfg d41-test 
     ./test_curl.sh
     
EOF

}
