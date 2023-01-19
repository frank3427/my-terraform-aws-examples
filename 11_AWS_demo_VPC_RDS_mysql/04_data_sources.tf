data aws_ami al2_x64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.2022*x86_64-gp2"]
  }
   owners = ["amazon"]
}