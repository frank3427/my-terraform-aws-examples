# data aws_ami al2_x64 {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-kernel-5.10-hvm-2.0.202*x86_64-gp2"]
#   }
#    owners = ["amazon"]
# }

# ---- AMI for Amazon Linux 2023 on X86_64 architecture
data aws_ami al2023_x64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*x86_64"]
  }
   owners = ["amazon"]
}