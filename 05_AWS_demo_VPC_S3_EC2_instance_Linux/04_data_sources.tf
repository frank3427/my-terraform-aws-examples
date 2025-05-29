data aws_ami al2_arm64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-arm64-gp2"]
  }
   owners = ["amazon"]
}

data aws_ami al2_x86-64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*x86_64-gp2"]
  }
   owners = ["amazon"]
}