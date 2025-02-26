# ------ Display the complete ssh command needed to connect to the instance
locals {
  username = "ec2-user"
}

output Instances {
  value = <<EOF


---- Demo purpose
In this demo, we create 3 VPCs in the same account and region.
All 3 VPCs are connected to a transit gateway.
Routing is enabled between all VPCs

---- You can SSH to the Linux EC2 instance in VPC #1 and ping EC2 instances in VPC #2 and #3
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo06b[0].public_ip}
ping ${format("%-15s", aws_instance.demo06b[1].private_ip)}     # ping from VPC #1 to VPC #2, should work
ping ${format("%-15s", aws_instance.demo06b[2].private_ip)}     # ping from VPC #1 to VPC #3, should work

---- You can SSH to the Linux EC2 instance in VPC #2 and ping EC2 instances in VPC #3 and #1
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo06b[1].public_ip}
ping ${format("%-15s", aws_instance.demo06b[2].private_ip)}     # ping from VPC #2 to VPC #3, should work
ping ${format("%-15s", aws_instance.demo06b[0].private_ip)}     # ping from VPC #2 to VPC #1, should work

---- You can SSH to the Linux EC2 instance in VPC #3 and ping EC2 instances in VPC #1 and #2
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo06b[2].public_ip}
ping ${format("%-15s", aws_instance.demo06b[0].private_ip)}     # ping from VPC #3 to VPC #1, should work
ping ${format("%-15s", aws_instance.demo06b[1].private_ip)}     # ping from VPC #3 to VPC #2, should work

EOF
}