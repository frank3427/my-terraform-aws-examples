data aws_ami al2_arm64_r1 {
  provider    = aws.r1
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.20221004.0-arm64-gp2"]
  }
   owners = ["amazon"]
}

data aws_ami al2_arm64_r2 {
  provider    = aws.r2
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.20221004.0-arm64-gp2"]
  }
   owners = ["amazon"]
}