data aws_ami al2023_x64 {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-202*x86_64"]
  }
   owners = ["amazon"]
}