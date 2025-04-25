data aws_ami al2_arm64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.202*-arm64-gp2"]
  }
   owners = ["amazon"]
}
