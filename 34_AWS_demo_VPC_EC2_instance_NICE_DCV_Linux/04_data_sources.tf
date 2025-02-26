# ---- AMI for Amazon Linux 2 on X86_64 architecture
data aws_ami al2_x86_64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["DCV-AmazonLinux2-x86_64-2023.*"]
  }
  owners = ["amazon"]
}
