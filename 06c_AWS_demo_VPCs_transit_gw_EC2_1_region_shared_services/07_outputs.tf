# ------ Display the complete ssh command needed to connect to the instance
locals {
  username = "ec2-user"
}

output Instances {
  value = <<EOF


---- Demo purpose
In this demo, we create 3 VPCs in the same account and region.
All 3 VPCs are connected to a transit gateway.
Routing is enabled like this:
- between VPCs #1 and #2
- between VPCs #1 and #3
- but not between VPCs #2 and #3

VPC #1 is used for shared services 

---- You can SSH to the Linux EC2 instance in VPC #1 and ping EC2 instances in VPC #2 and #3
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo06c[0].public_ip}
ping ${format("%-15s", aws_instance.demo06c[1].private_ip)}     # ping from VPC #1 to VPC #2, should work
ping ${format("%-15s", aws_instance.demo06c[2].private_ip)}     # ping from VPC #1 to VPC #3, should work

---- You can SSH to the Linux EC2 instance in VPC #2 and ping EC2 instances in VPC #3 and #1
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo06c[1].public_ip}
ping ${format("%-15s", aws_instance.demo06c[2].private_ip)}     # ping from VPC #2 to VPC #3, should NOT work as there is no route
ping ${format("%-15s", aws_instance.demo06c[0].private_ip)}     # ping from VPC #2 to VPC #1, should work

---- You can SSH to the Linux EC2 instance in VPC #3 and ping EC2 instances in VPC #1 and #2
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo06c[2].public_ip}
ping ${format("%-15s", aws_instance.demo06c[0].private_ip)}     # ping from VPC #3 to VPC #1, should work
ping ${format("%-15s", aws_instance.demo06c[1].private_ip)}     # ping from VPC #3 to VPC #2, should NOT work as there is no route

EOF
}