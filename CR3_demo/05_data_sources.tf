data aws_ami al2_arm64_r1 {
  provider    = aws.r1
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-arm64-gp2"]
  }
   owners = ["amazon"]
}

data aws_ami al2_arm64_r2 {
  provider    = aws.r2
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-arm64-gp2"]
  }
   owners = ["amazon"]
}