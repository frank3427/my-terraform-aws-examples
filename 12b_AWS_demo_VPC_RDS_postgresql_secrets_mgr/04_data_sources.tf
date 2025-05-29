data aws_ami al2_x64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*x86_64-gp*"]
  }
   owners = ["amazon"]
}