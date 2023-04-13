# ---- AMI for Amazon Linux 2 on X86_64 architecture
data aws_ami al2_x86_64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.2022*x86_64-gp2"]    # use old 2022 AMIs to have missing patches
  }
   owners = ["amazon"]
}
